require 'seedable'
class User < ActiveRecord::Base
  include Seedable

  attr_writer(:reset_password_method)
  
  has_many(:responses, :inverse_of => :user)
  has_many(:broadcast_addressings, :inverse_of => :user)
  has_many(:assignments, :autosave => true, :dependent => :destroy, :validate => true, :inverse_of => :user)
  has_many(:missions, :through => :assignments, :order => "missions.created_at DESC")
  belongs_to(:current_mission, :class_name => "Mission")
  
  accepts_nested_attributes_for(:assignments, :allow_destroy => true)
  
  acts_as_authentic do |c| 
    c.disable_perishable_token_maintenance = true
    c.logged_in_timeout(60.minutes)
    c.validates_format_of_login_field_options = {:with => /[\a-zA-Z0-9\.]+/, :message => "can only contain letters, numbers, or '.'"}
    
    # email is not mandatory, but must be valid if given
    c.merge_validates_format_of_email_field_options(:allow_blank => true)
    c.merge_validates_uniqueness_of_email_field_options(:unless => Proc.new{|u| u.email.blank?})
  end

  before_validation(:clean_fields)
  before_destroy(:check_assoc)
  
  validates(:name, :presence => true)
  validate(:phone_length_or_empty)
  validate(:must_have_password_reset_on_create)
  validate(:password_reset_cant_be_email_if_no_email)
  validate(:no_duplicate_assignments)
  validate(:must_have_assignments_if_not_admin)
  validate(:ensure_current_mission_is_valid)
  
  default_scope(order("users.name"))
  scope(:assigned_to, lambda{|m| where("users.id IN (SELECT user_id FROM assignments WHERE mission_id = ?)", m.id)})
  
  # we want all of these on one page for now
  self.per_page = 1000000

  def self.new_with_login_and_password(params)
    u = new(params)
    u.reset_password
    u
  end
  def self.random_password(size = 6)
    charset = %w{2 3 4 6 7 9 a c d e f g h j k m n p q r t v w x y z}
    (0...size).map{charset.to_a[rand(charset.size)]}.join
  end
  def self.find_by_credentials(login, password)
    user = find_by_login(login)
    (user && user.valid_password?(password)) ? user : nil
  end
  
  def self.suggest_login(name)
    # if it looks like a person's name, suggest f. initial + l. name
    if m = name.match(/^([a-z][a-z']+) ([a-z'\- ]+)$/i)
      l = $1[0,1] + $2.gsub(/[^a-z]/i, "")
    # otherwise just use the whole thing and strip out weird chars
    else
      l = name.gsub(/[^a-z0-9\.]/i, "")
    end

    # convert to lowercase
    suggestion = l[0,10].downcase
    
    # if this login is taken, add a number to the end
    if find_by_login(suggestion)
      
      # get suffixes of all logins with same prefix
      suffixes = where("login LIKE '#{suggestion}%'").all.collect{|u| u.login[suggestion.length..-1].to_i}
      
      # get max suffix (skip 1 if necessary)
      suffix = suffixes.max + 1
      suffix = 2 if suffix <= 1
      
      # apply suffix
      suggestion += suffix.to_s
    end
    
    suggestion
  end
  
  def self.search_qualifiers
    [
      Search::Qualifier.new(:label => "name", :col => "users.name", :default => true, :partials => true),
      Search::Qualifier.new(:label => "login", :col => "users.login", :default => true),
      Search::Qualifier.new(:label => "email", :col => "users.email", :partials => true),
      Search::Qualifier.new(:label => "phone", :col => "users.phone", :partials => true)
    ]
  end

  def self.search_examples
    ["pinchy lombard", "phone:+44"]
  end
  
  def reset_password
    self.password = self.password_confirmation = self.class.random_password
  end
  
#  def generate_login!
#    base = "#{name.gsub(/[^A-Za-z]/,'')[0,1]}#{last_name.gsub(/[^A-Za-z]/,'')[0,7]}".downcase.normalize
#    try = 1
#    until self.class.find_by_login(self.login = base + (try > 1 ? try.to_s : "")).nil?
#      try += 1
#    end
#  end
  def deliver_intro!
    reset_perishable_token!
    Notifier.intro(self).deliver
  end
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver  
  end
  def full_name
    name
  end
  def reset_password_method
    @reset_password_method.nil? ? "dont" : @reset_password_method
  end
  def reset_password_if_requested
    if %w[email print].include?(reset_password_method)
      reset_password and save
    end
    if reset_password_method == "email"
      # only send intro if he/she has never logged in
      (login_count || 0) > 0 ? deliver_password_reset_instructions! : deliver_intro!
    end
  end
  def to_vcf
    "BEGIN:VCARD\nVERSION:3.0\nFN:#{name}\n" + 
    (email ? "EMAIL:#{email}\n" : "") +
    (phone ? "TEL;TYPE=CELL:#{phone}\n" : "") + 
    (phone2 ? "TEL;TYPE=CELL:#{phone2}\n" : "") + 
    "END:VCARD"
  end
  def can_get_sms?; !(phone.blank? && phone2.blank?) end
  def can_get_email?; !email.blank?; end
  
  def assignments_by_mission
    @assignments_by_mission ||= Hash[*assignments.collect{|a| [a.mission, a]}.flatten]
  end
  
  def latest_mission
    missions.first
  end
  
  # gets the user's role for the given mission
  # returns nil if the user is not assigned to the mission
  def role(mission)
    nn(assignments_by_mission[mission]).role
  end
  
  # returns all missions that the user has access to
  def accessible_missions
    @accessible_missions ||= Permission.restrict(Mission, :user => self)
  end
  
  # tests if user can access the given mission
  def can_access_mission?(mission)
    accessible_missions.include?(mission)
  end
  
  # determines if the user's role for the given mission is as an observer
  def observer?(mission)
    (r = role(mission)) ? r.observer? : false
  end
  
  # if user has no current mission, choose one (if assigned to any)
  def set_current_mission
    # ensure no current mission set if the user has no assignments
    if assignments.active.empty?
      update_attributes(:current_mission_id => nil) 
    # else if user has no current mission, pick one
    elsif current_mission.nil?
      update_attributes(:current_mission_id => assignments.active.sorted_recent_first.first.mission_id)
    end
  end
  
  private
    def clean_fields
      self.phone = phone.blank? ? nil : "+" + phone.gsub(/[^0-9]/, "")
      self.phone2 = phone2.blank? ? nil : "+" + phone2.gsub(/[^0-9]/, "")
      self.login = login.downcase
      return true
    end
    
    def phone_length_or_empty
      errors.add(:phone, "must be at least 9 digits.") unless phone.blank? || phone.size >= 10
      errors.add(:phone2, "must be at least 9 digits.") unless phone2.blank? || phone2.size >= 10
    end
    
    def check_assoc
      # Can't delete users with related responses.
      unless responses.empty?
        raise "You can't delete #{name} because he/she has associated responses."
      end
    end
    
    def must_have_password_reset_on_create
      if new_record? && reset_password_method == "dont"
        errors.add(:base, "You must choose a password creation method")
      end
    end
    
    def password_reset_cant_be_email_if_no_email
      if reset_password_method == "email" && email.blank?
        verb = new_record? ? "send" : "reset"
        errors.add(:base, "You can't #{verb} password by email because you didn't specify an email address.")
      end
    end
    
    def no_duplicate_assignments
      errors.add(:base, "There are duplicate assignments.") if Assignment.duplicates?(assignments)
    end
    
    def must_have_assignments_if_not_admin
      if !admin? && assignments.reject{|a| a.marked_for_destruction?}.empty?
        errors.add(:assignments, "can't be empty if not admin")
      end
    end
    
    # if current mission is not accessible, set to nil
    def ensure_current_mission_is_valid
      self.current_mission_id = nil if !current_mission_id.nil? && !Permission.user_can_access_mission(self, current_mission)
    end
end
