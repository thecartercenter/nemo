class User < ActiveRecord::Base
  ROLES = %w[observer staffer coordinator]
  SESSION_TIMEOUT = 60.minutes

  attr_writer(:reset_password_method)

  # allow can? and cannot? to be called directly on user
  delegate :can?, :cannot?, :to => :ability

  has_many(:responses, :inverse_of => :user)
  has_many(:broadcast_addressings, :inverse_of => :user, :dependent => :destroy)
  has_many(:assignments, :autosave => true, :dependent => :destroy, :validate => true, :inverse_of => :user)
  has_many(:missions, :through => :assignments, :order => "missions.created_at DESC")
  belongs_to(:current_mission, :class_name => "Mission")

  accepts_nested_attributes_for(:assignments, :allow_destroy => true)

  acts_as_authentic do |c|
    c.disable_perishable_token_maintenance = true
    c.logged_in_timeout(SESSION_TIMEOUT)
    c.validates_format_of_login_field_options = {:with => /[\a-zA-Z0-9\.]+/, :message => "can only contain letters, numbers, or '.'"}

    # email is not mandatory, but must be valid if given
    c.merge_validates_format_of_email_field_options(:allow_blank => true)
    c.merge_validates_uniqueness_of_email_field_options(:unless => Proc.new{|u| u.email.blank?})
  end

  after_initialize(:set_default_pref_lang)
  after_initialize(:set_default_login)
  before_validation(:clean_fields)
  before_destroy(:check_assoc)
  before_validation(:generate_password_if_none)
  after_save(:rebuild_ability)

  validates(:name, :presence => true)
  validates(:pref_lang, :presence => true)
  validate(:phone_length_or_empty)
  validate(:must_have_password_reset_on_create)
  validate(:password_reset_cant_be_email_if_no_email)
  validate(:no_duplicate_assignments)
  validate(:must_have_assignments_if_not_admin)
  validate(:ensure_current_mission_is_valid)
  validate(:phone_should_be_unique)

  scope(:by_name, order("users.name"))
  scope(:assigned_to, lambda{|m| where("users.id IN (SELECT user_id FROM assignments WHERE mission_id = ?)", m.id)})
  scope(:with_assoc, includes(:missions, {:assignments => :mission}))

  # we want all of these on one page for now
  self.per_page = 1000000

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
      Search::Qualifier.new(:name => "name", :col => "users.name", :default => true, :partials => true),
      Search::Qualifier.new(:name => "login", :col => "users.login", :default => true),
      Search::Qualifier.new(:name => "email", :col => "users.email", :partials => true),
      Search::Qualifier.new(:name => "phone", :col => "users.phone", :partials => true)
    ]
  end

  def self.search_examples
    ["john smith", "#{I18n.t('search_qualifiers.phone')}:+44"]
  end

  # returns an array of hashes of format {:name => "Some User", :count => 2}
  # of user response counts for the given mission
  def self.sorted_response_counts(mission, limit)
    find_by_sql(["SELECT users.name AS name, COUNT(DISTINCT responses.id) AS response_count
      FROM users
        INNER JOIN assignments ON users.id = assignments.user_id AND assignments.mission_id = ?
        LEFT JOIN responses ON responses.user_id = users.id AND responses.mission_id = ?
      GROUP BY users.id, users.name
      ORDER BY response_count
      LIMIT ?", mission.id, mission.id, limit])
  end

  def reset_password
    self.password = self.password_confirmation = self.class.random_password
  end

  def deliver_intro!
    reset_perishable_token!
    Notifier.intro(self).deliver
  end

  # sends password reset instructions to the user's email
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

  def can_get_sms?
    !(phone.blank? && phone2.blank?)
  end

  def can_get_email?
    !email.blank?
  end

  def assignments_by_mission
    @assignments_by_mission ||= Hash[*assignments.collect{|a| [a.mission, a]}.flatten]
  end

  # returns the last mission with which this user is associated
  def latest_mission
    # the mission association is already sorted by date so we just take the last one
    missions[missions.size-1]
  end

  # gets the user's role for the given mission
  # returns nil if the user is not assigned to the mission
  def role(mission)
    nn(assignments_by_mission[mission]).role
  end

  # checks if the user can perform the given role for the given mission
  # mission defaults to user's current mission
  def role?(base_role, mission = nil)
    # admins can do anything
    return true if admin?

    # default to the current mission if none given
    mission ||= current_mission

    # if no mission then the answer is trivially false
    return false if mission.nil?

    # get the user's role for the specified mission
    mission_role = role(mission)

    # if the role is nil, we can return false
    if mission_role.nil?
      return false
    # otherwise we compare the role indices
    else
      ROLES.index(base_role.to_s) <= ROLES.index(mission_role)
    end
  end

  # returns all missions that the user has access to
  # caches in case of multiple accesses
  def accessible_missions
    @accessible_missions ||= Mission.accessible_by(ability, :switch_to)
  end

  # if user has no current mission, choose one (if assigned to any)
  def set_current_mission
    # ensure no current mission set if the user has no assignments
    if assignments.active.empty?
      change_mission!(nil)
    # else if user has no current mission, pick one
    elsif current_mission.nil?
      change_mission!(assignments.active.sorted_recent_first.first.mission)
    end
  end

  # changes the user's current mission to the given mission. saves without validating.
  def change_mission!(mission)
    self.current_mission = mission
    save(:validate => false)
  end

  # builds and returns a CanCan ability class for this user
  def ability
    rebuild_ability unless @ability
    return @ability
  end

  def session_time_left
    SESSION_TIMEOUT - (Time.now - last_request_at)
  end

  def as_json(options = {})
    {:name => name}
  end

  # returns hash of missions to roles
  def roles
    Hash[*assignments.map{|a| [a.mission, a.role]}.flatten]
  end

  private
    def clean_fields
      self.phone = phone.blank? ? nil : "+" + phone.gsub(/[^0-9]/, "")
      self.phone2 = phone2.blank? ? nil : "+" + phone2.gsub(/[^0-9]/, "")
      self.login = login.downcase
      return true
    end

    def phone_length_or_empty
      errors.add(:phone, :at_least_digits, :num => 9) unless phone.blank? || phone.size >= 10
      errors.add(:phone2, :at_least_digits, :num => 9) unless phone2.blank? || phone2.size >= 10
    end

    def check_assoc
      # can't delete users with related responses.
      raise DeletionError.new(:cant_delete_if_responses) unless responses.empty?
    end

    def must_have_password_reset_on_create
      if new_record? && reset_password_method == "dont"
        errors.add(:base, :must_choose_passwd_method)
      end
    end

    def password_reset_cant_be_email_if_no_email
      if reset_password_method == "email" && email.blank?
        verb = new_record? ? "send" : "reset"
        errors.add(:base, :cant_passwd_email, :verb => verb)
      end
    end

    def no_duplicate_assignments
      errors.add(:base, :duplicate_assignments) if Assignment.duplicates?(assignments.reject{|a| a.marked_for_destruction?})
    end

    def must_have_assignments_if_not_admin
      if !admin? && assignments.reject{|a| a.marked_for_destruction?}.empty?
        errors.add(:assignments, :cant_be_empty_if_not_admin)
      end
    end

    # if current mission is not accessible, set to nil
    def ensure_current_mission_is_valid
      if !current_mission_id.nil?
        # the current mission should never be non-nil on a new user
        raise "current mission can't be set on new user" if new_record?

        # if current mission can't be switched to by self, set it to nil
        # not sure if this belongs here since change_mission! saves without validating, but leaving it here for now
        self.current_mission_id = nil unless can?(:switch_to, current_mission)
      end
    end

    # ensures phone and phone2 are unique
    def phone_should_be_unique
      [:phone, :phone2].each do |field|
        val = send(field)
        # if phone/phone2 is not nil and we can find a user with a different ID from ours that has a matching phone OR phone2
        # then it's not unique
        # start building relation
        rel = User.where("phone = ? OR phone2 = ?", val, val)
        # add ID clause if this is not a new record
        rel = rel.where("id != ?", id) unless new_record?
        if !val.nil? && rel.count > 0
          errors.add(field, :phone_assigned_to_other)
        end
      end
    end

    # generates a random password before validation if this is a new record, unless one is already set
    def generate_password_if_none
      reset_password if new_record? && password.blank? && password_confirmation.blank?
    end

    # the ability object must be rebuilt after saves in case something relevant to abilities changed
    def rebuild_ability
      @ability = Ability.new(self)
      return true
    end

    # sets the user's preferred language to the mission default
    def set_default_pref_lang
      begin
        self.pref_lang ||= configatron.has_key?(:preferred_locales) ? configatron.preferred_locales.first.to_s : 'en'
      rescue ActiveModel::MissingAttributeError
        # we rescue this error in case find_by_sql is being used
      end
    end

    # sets the user's default login name
    def set_default_login
      begin
        self.login ||= self.class.suggest_login(name) unless name.blank?
      rescue ActiveModel::MissingAttributeError
        # we rescue this error in case find_by_sql is being used
      end
    end

end
