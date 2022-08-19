# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: users
#
#  id                :uuid             not null, primary key
#  active            :boolean          default(TRUE), not null
#  admin             :boolean          default(FALSE), not null
#  api_key           :string(255)
#  birth_year        :integer
#  crypted_password  :string(255)      not null
#  current_login_at  :datetime
#  editor_preference :string
#  email             :string(255)
#  experience        :text
#  gender            :string(255)
#  gender_custom     :string(255)
#  import_num        :integer
#  last_request_at   :datetime
#  login             :string(255)      not null
#  login_count       :integer          default(0), not null
#  name              :string(255)      not null
#  nationality       :string(255)
#  notes             :text
#  password_salt     :string(255)      not null
#  perishable_token  :string(255)
#  persistence_token :string(255)
#  phone             :string(255)
#  phone2            :string(255)
#  pref_lang         :string(255)      default("en"), not null
#  sms_auth_code     :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  last_mission_id   :uuid
#
# Indexes
#
#  index_users_on_email            (email)
#  index_users_on_last_mission_id  (last_mission_id)
#  index_users_on_login            (login) UNIQUE
#  index_users_on_name             (name)
#  index_users_on_sms_auth_code    (sms_auth_code) UNIQUE
#
# Foreign Keys
#
#  users_last_mission_id_fkey  (last_mission_id => missions.id) ON DELETE => nullify ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class User < ApplicationRecord
  include Cacheable
  include Wisper.model

  ROLES = %w[enumerator reviewer staffer coordinator].freeze
  SESSION_TIMEOUT = (Rails.env.development? ? 2.weeks : 60.minutes)
  GENDER_OPTIONS = %w[man woman no_answer specify].freeze
  PASSWORD_FORMAT = /\A.*(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).*\z/.freeze
  DEFAULT_RECENT_LOGIN_MAX_AGE = 60.minutes

  attr_writer(:reset_password_method)
  attr_accessor(:password_confirmation)

  has_many :responses, inverse_of: :user, dependent: :restrict_with_exception
  has_many :reviewed_responses, class_name: "Response", foreign_key: :reviewer_id,
                                inverse_of: :reviewer, dependent: :restrict_with_exception
  has_many :checked_out_responses, class_name: "Response", foreign_key: :checked_out_by_id,
                                   inverse_of: :checked_out_by, dependent: :nullify
  has_many :broadcast_addressings, inverse_of: :addressee, foreign_key: :addressee_id, dependent: :destroy
  has_many :form_forwardings, inverse_of: :recipient, foreign_key: :recipient_id, dependent: :destroy
  has_many :assignments, -> { includes(:mission) }, autosave: true, dependent: :destroy,
                                                    validate: true, inverse_of: :user
  has_many :missions, -> { order("missions.created_at DESC") }, through: :assignments
  has_many :operations, inverse_of: :creator, foreign_key: :creator_id, dependent: :destroy
  has_many :reports, inverse_of: :creator, foreign_key: :creator_id,
                     dependent: :nullify, class_name: "Report::Report"
  has_many :sms_messages, class_name: "Sms::Message", inverse_of: :user, dependent: :restrict_with_exception
  has_many :user_group_assignments, dependent: :destroy
  has_many :user_groups, through: :user_group_assignments
  belongs_to :last_mission, class_name: "Mission"

  accepts_nested_attributes_for(:assignments, allow_destroy: true)
  accepts_nested_attributes_for(:user_groups)

  acts_as_authentic do |c|
    c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    c.crypto_provider = Authlogic::CryptoProviders::SCrypt

    c.disable_perishable_token_maintenance = true
    c.perishable_token_valid_for = 1.week
    c.logged_in_timeout(SESSION_TIMEOUT)
  end

  before_validation :normalize_fields
  before_validation :generate_password_if_none
  before_save :clear_assignments_without_roles
  before_create :regenerate_api_key
  before_create :regenerate_sms_auth_code
  # call before_destroy before dependent: :destroy associations
  # cf. https://github.com/rails/rails/issues/3458

  normalize_attribute :login, with: %i[strip downcase]

  validates :name, presence: true
  validates :pref_lang, presence: true
  validate :phone_length_or_empty
  validate :must_have_password_on_enter
  validate :password_reset_cant_be_email_if_no_email
  validate :no_duplicate_assignments
  validates :login, format: {with: /\A[[:word:].]+\z/},
                    uniqueness: {case_sensitive: true}
  validates :email, format: {with: /\A\S+@\S+\.\S+\z/},
                    length: {maximum: 100},
                    allow_blank: true

  # This validation causes issues when deleting missions,
  # orphaned users can no longer change their profile or password
  # which can be an issue if they will be being re-assigned
  # validate :must_have_assignments_if_not_admin
  validates :password,
    confirmation: {if: :require_password?},
    format: {with: PASSWORD_FORMAT, if: :require_password?, message: :invalid_password},
    length: {minimum: 8, if: :require_password?}
  validates :password_confirmation, length: {minimum: 8}, if: :require_password?

  clone_options follow: %i[assignments user_group_assignments]

  scope :by_name, -> { order("users.name") }
  scope :assigned_to, ->(mission) { where(id: Assignment.select(:user_id).where(mission_id: mission.id)) }
  scope :with_only_one_assignment, lambda {
    count_query = Assignment.select("COUNT(*)").where("user_id = users.id").to_sql
    where("(#{count_query}) = 1")
  }
  scope :assigned_only_to, ->(mission) { assigned_to(mission).with_only_one_assignment }
  scope :with_assoc, lambda {
    includes(:missions, {assignments: :mission}, user_group_assignments: :user_group)
  }
  scope :with_groups, -> { joins(:user_groups) }
  scope :name_matching, ->(q) { where("name ILIKE ?", "%#{q}%") }
  scope :with_roles, lambda { |m, roles|
                       includes(:missions, assignments: :mission)
                         .where(assignments: {mission: m.try(:id), role: roles})
                     }

  scope :by_phone, ->(phone) { where("phone = :phone OR phone2 = :phone2", phone: phone, phone2: phone) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :not_self, ->(s) { s.persisted? ? where.not(id: s.id) : all }

  def self.random_password(size = 12)
    size = 12 if size < 12

    num_size = size.even? ? 2 : 3
    symbol_size = 2
    alpha_size = (size - num_size - symbol_size) / 2

    num = %w[2 3 4 6 7 9]
    alpha = %w[a c d e f g h j k m n p q r t v w x y z]
    symbol = %w[@ & # + %]

    alpha_component = alpha_size.times.map { alpha.sample }
    upper_component = alpha_size.times.map { alpha.sample.upcase }
    num_component = num_size.times.map { num.sample }
    symbol_component = symbol_size.times.map { symbol.sample }

    (alpha_component + upper_component + num_component + symbol_component).shuffle.join
  end

  def self.find_with_credentials(login, password)
    user = find_by(login: login)
    user&.valid_password?(password) ? user : nil
  rescue ActiveRecord::StatementInvalid
    return nil if login.encoding == Encoding::UTF_8 && password.encoding == Encoding::UTF_8
    find_with_credentials(reencode(login), reencode(password))
  end

  # Convert strings from Basic auth with Latin-1 encoding into UTF-8 so we can recognize characters:
  # https://forum.getodk.org/t/support-for-special-characters-in-usernames-basic-auth/27696
  def self.reencode(str)
    str.force_encoding("iso8859-1")
    str.valid_encoding? ? str.encode("utf-8") : ""
  end

  # Returns an array of hashes of format {name: "Some User", response_count: 2}
  # of enumerator response counts for the given mission
  def self.sorted_enumerator_response_counts(mission, limit)
    # First it tries to get user enumerators that don't have any response
    result = enumerators_without_responses(mission, limit)
    return result unless result.length < limit

    # If the first query didn't get the necessary users quantity,
    # we then get the ones with lowest activy
    find_by_sql(["SELECT users.name, rc.response_count FROM users
      JOIN (
        SELECT assignments.user_id, COUNT(DISTINCT responses.id) AS response_count
        FROM assignments
          LEFT JOIN responses ON responses.user_id = assignments.user_id AND responses.mission_id = ?
        WHERE assignments.role = 'enumerator' AND assignments.mission_id = ?
        GROUP BY assignments.user_id
        ORDER BY response_count
        LIMIT ?
      ) as rc ON users.id = rc.user_id", mission.id, mission.id, limit]).reverse
  end

  # Returns an array of hashes of format {name: "Some User", response_count: 0}
  # of enumerators that doesn't have responses on the mission
  def self.enumerators_without_responses(mission, limit)
    find_by_sql(["SELECT users.name, 0 as response_count FROM users
      JOIN (
        SELECT a.user_id FROM assignments a
        WHERE NOT EXISTS (SELECT 1 FROM responses r
            WHERE r.user_id = a.user_id AND r.mission_id = ?)
          AND a.role = 'enumerator' AND a.mission_id = ?
        LIMIT ?
      ) as rc ON users.id = rc.user_id
      ORDER BY users.name", mission.id, mission.id, limit])
  end

  # Returns all non-admin users in the form's mission with the given role that have
  # not submitted any responses to the form
  #
  # options[:role] the role to check for
  # options[:limit] how many users we want to fetch from the db. This method returns at most
  #   one more than this number so you can report truncation to the user.
  def self.without_responses_for_form(form, options)
    find_by_sql(["SELECT * FROM users
      INNER JOIN assignments ON assignments.user_id = users.id
      WHERE assignments.mission_id = ?
        AND assignments.role = ?
        AND users.admin = FALSE
        AND NOT EXISTS (
          SELECT 1
          FROM responses
          WHERE responses.user_id = users.id AND responses.form_id = ?
        )
      ORDER BY users.name
      LIMIT ?", form.mission.id, options[:role].to_s, form.id, options[:limit] + 1])
  end

  # generates a cache key for the set of all users for the given mission.
  # the key will change if the number of users changes, or if a user is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(rel: assigned_to(mission), prefix: "mission-#{mission.id}")
  end

  def reset_password
    self.password = self.password_confirmation = self.class.random_password
  end

  def full_name
    name
  end

  def group_names
    user_groups.map(&:name).join(", ")
  end

  def active?
    active
  end

  def activate!(bool)
    update_attribute(:active, bool)
  end

  def reset_password_method
    @reset_password_method.nil? ? "dont" : @reset_password_method
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
    email.present?
  end

  def assignments_by_mission
    @assignments_by_mission ||= Hash[*assignments.collect { |a| [a.mission, a] }.flatten]
  end

  # returns the last mission with which this user is associated
  def latest_mission
    # the mission association is already sorted by date so we just take the last one
    missions[missions.size - 1]
  end

  # gets the user's role for the given mission
  # returns nil if the user is not assigned to the mission
  def role(mission)
    assignments_by_mission[mission]&.role
  end

  # checks if the user can perform the given role for the given mission
  # mission defaults to user's current mission
  def role?(base_role, mission)
    # admins can do anything
    return true if admin?

    # if no mission then the answer is trivially false
    return false if mission.nil?

    # get the user's role for the specified mission
    mission_role = role(mission)

    # if the role is nil, we can return false
    if mission_role.nil?
      false
    # otherwise we compare the role indices
    else
      ROLES.index(base_role.to_s) <= ROLES.index(mission_role)
    end
  end

  def enumerator_only?
    assignments.all? { |a| a.role === "enumerator" }
  end

  def session_time_left
    SESSION_TIMEOUT - (Time.zone.now - last_request_at)
  end

  def current_login_age
    Time.zone.now - current_login_at if current_login_at.present?
  end

  def current_login_recent?(max_age = nil)
    max_age ||= DEFAULT_RECENT_LOGIN_MAX_AGE
    current_login_age < max_age if current_login_at.present?
  end

  # returns hash of missions to roles
  def roles
    Hash[*assignments.map { |a| [a.mission, a.role] }.flatten]
  end

  def regenerate_api_key
    # loop if necessary till unique token generated
    loop do
      self.api_key = SecureRandom.hex
      break unless User.exists?(api_key: api_key)
    end
  end

  def regenerate_sms_auth_code
    loop do
      self.sms_auth_code = Random.alphanum(4)
      break unless User.exists?(sms_auth_code: sms_auth_code)
    end
  end

  # Returns the system's best guess as to which mission this user would like to see.
  def best_mission
    if last_mission && (admin? || assignments.map(&:mission).include?(last_mission))
      last_mission
    elsif assignments.any?
      assignments.max_by(&:updated_at).mission
    end
  end

  def remember_last_mission(mission)
    self.last_mission = mission
  end

  private

  def normalize_fields
    %w[phone phone2 name email].each { |f| send(f.to_s).try(:strip!) }
    self.email = nil if email.blank?
    self.phone = PhoneNormalizer.normalize(phone)
    self.phone2 = PhoneNormalizer.normalize(phone2)
  end

  def phone_length_or_empty
    errors.add(:phone, :at_least_digits, num: 9) unless phone.blank? || phone.size >= 10
    errors.add(:phone2, :at_least_digits, num: 9) unless phone2.blank? || phone2.size >= 10
  end

  def must_have_password_on_enter
    entering_password = %w[enter enter_and_show].include?(reset_password_method)
    errors.add(:password, :blank) if entering_password && password.blank?
  end

  def password_reset_cant_be_email_if_no_email
    sending_email = reset_password_method == "email"
    errors.add(:reset_password_method, :cant_passwd_email) if sending_email && email.blank?
  end

  def no_duplicate_assignments
    if Assignment.duplicates?(assignments.reject(&:marked_for_destruction?))
      errors.add(:assignments, :duplicate_assignments)
    end
  end

  def must_have_assignments_if_not_admin
    if !admin? && assignments.reject(&:marked_for_destruction?).empty?
      errors.add(:assignments, :cant_be_empty_if_not_admin)
    end
  end

  def clear_assignments_without_roles
    assignments.delete(assignments.select(&:no_role?))
  end

  # generates a random password before validation if this is a new record, unless one is already set
  def generate_password_if_none
    reset_password if new_record? && password.blank? && password_confirmation.blank?
  end
end
