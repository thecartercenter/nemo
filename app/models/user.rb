# Elmo - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# Elmo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Elmo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Elmo.  If not, see <http://www.gnu.org/licenses/>.
# 
class User < ActiveRecord::Base
  attr_writer(:reset_password_method)
  
  belongs_to(:role)
  belongs_to(:language)
  belongs_to(:location)
  before_validation(:clean_fields)
  before_destroy(:check_assoc)
  has_many(:responses)
  has_many(:broadcast_addressings)
  
  acts_as_authentic do |c| 
    c.disable_perishable_token_maintenance = true
    c.logged_in_timeout(60.minutes)
    c.validates_format_of_login_field_options = {:with => /[\a-zA-Z0-9\.]+/, :message => "can only contain letters, numbers, or '.'"}
  end
  
  validates(:name, :presence => true)
  validates(:role_id, :presence => true)
  validates(:language_id, :presence => true)
  validate(:phone_length_or_empty)
  validate(:must_have_password_reset_on_create)
  
  before_validation(:no_mobile_phone_if_no_phone)
  
  def self.per_page
    # we want all of these on one page for now
    10000000
  end
  def self.select_options
    find(:all, :order => "name").collect{|u| [u.name, u.id]}
  end
  def self.sorted(params)
    params.merge!(:order => "users.name")
    paginate(:all, params)
  end
  def self.default(params = {})
    User.new({:active => true, :language_id => Language.english.id}.merge(params))
  end
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
  
  def self.default_eager
    [:language, :role]
  end
  
  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_fields
    {:name => {:colname => "users.name", :default => true, :regexp => true},
     :login => {:colname => "users.login", :default => true, :regexp => true},
     :language => {:colname => "languages.name", :default => false, :regexp => false},
     :role => {:colname => "roles.name", :default => false, :regexp => false},
     :email => {:colname => "users.email", :default => false, :regexp => true},
     :phone => {:colname => "users.phone", :default => false, :regexp => true}}
  end
  
  # returns the lhs, operator, and rhs of a query fragment with the given field and term
  def self.query_fragment(field, term)
    [search_fields[field][:colname], "like", "%#{term}%"]
  end
  
  def self.search_examples
    ["pinchy lombard", 'role:observer', "language:english", "phone:+44"]
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
  def phone_number
    phone.blank? ? "" : phone + (phone_is_mobile? ? " [m]" : "")
  end
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
      (login_count || 0) > 0 ? deliver_password_reset_instructions! : deliver_intro!
    end
  end
  def to_vcf
    "BEGIN:VCARD\nVERSION:3.0\nFN:#{name}\nEMAIL:#{email}\n" +
    (phone ? "TEL;TYPE=#{phone_is_mobile? ? 'CELL' : 'WORK'}:#{phone}\n" : "") + "END:VCARD"
  end
  def can_get_sms?; !phone.blank? && phone_is_mobile; end
  
  def is_observer?; role ? role.is_observer? : false; end
  def is_admin?; role ? role.is_admin? : false; end
  
  private
    def clean_fields
      self.phone = "+" + phone.gsub(/[^0-9]/, "") unless phone.blank?
      self.login = login.downcase
      return true
    end
    
    def phone_length_or_empty
      errors.add(:phone, "must be at least 9 digits.") unless phone.blank? || phone.size >= 10
    end
    
    def check_assoc
      # Can't delete users with related responses.
      unless responses.empty?
        raise("You can't delete #{name} because he/she has associated responses." +
          (active? ? " You could set him/her to inactive instead." : ""))
      end
    end
    
    def must_have_password_reset_on_create
      if new_record? && password.blank? && reset_password_method == "dont"
        errors.add(:base, "You must choose a password creation method")
      end
    end
    
    def no_mobile_phone_if_no_phone
      self.phone_is_mobile = false if phone.blank?
      return true
    end
end
