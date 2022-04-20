# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: settings
#
#  id                           :uuid             not null, primary key
#  default_outgoing_sms_adapter :string(255)
#  frontlinecloud_api_key       :string(255)
#  generic_sms_config           :jsonb
#  incoming_sms_numbers         :jsonb            not null
#  incoming_sms_token           :string(255)
#  override_code                :string(255)
#  preferred_locales            :jsonb            not null
#  theme                        :string           default("nemo"), not null
#  timezone                     :string(255)      default("UTC"), not null
#  twilio_account_sid           :string(255)
#  twilio_auth_token            :string(255)
#  twilio_phone_number          :string(255)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  mission_id                   :uuid
#
# Indexes
#
#  index_settings_on_mission_id          (mission_id) UNIQUE
#  index_settings_on_mission_id_IS_NULL  (((mission_id IS NULL))) UNIQUE WHERE (mission_id IS NULL)
#
# Foreign Keys
#
#  settings_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# Stores and manages settings per-mission and admin mode.
class Setting < ApplicationRecord
  include MissionBased

  KEYS_TO_COPY_FROM_ROOT = %i[default_outgoing_sms_adapter frontlinecloud_api_key incoming_sms_numbers
                              preferred_locales theme timezone
                              twilio_account_sid twilio_auth_token twilio_phone_number].freeze

  scope :by_mission, ->(m) { where(mission: m) }

  before_validation :normalize_locales
  before_validation :normalize_incoming_sms_numbers
  before_validation :normalize_twilio_phone_number
  before_validation :clear_sms_fields_if_requested
  before_validation :jsonify_generic_sms_config

  validate :locales_are_valid
  validate :one_locale_must_have_translations
  validate :sms_adapter_is_valid
  validate :sms_credentials_are_valid
  validate :generic_sms_valid_json
  validate :generic_sms_valid_keys
  validate :generic_sms_required_keys

  before_save :save_sms_credentials

  attr_accessor :twilio_auth_token1, :frontlinecloud_api_key1, :clear_twilio, :clear_frontlinecloud,
    :generic_sms_json_error
  attr_writer :generic_sms_config_str

  def self.with_cache
    Thread.current[:mission_config_cache] = {}
    yield
    Thread.current[:mission_config_cache] = nil
  end

  # Gets the setting for the given mission. If nil is given, gets the root setting, which should always
  # exist as it's system seed data.
  def self.for_mission(mission)
    if (cache = Thread.current[:mission_config_cache])
      mission_id = mission.is_a?(String) ? mission : mission&.id
      cache[mission_id] ||= find_by(mission: mission)
    else
      find_by(mission: mission)
    end
  end

  def self.root
    for_mission(nil)
  end

  # Builds and returns (but doesn't save) a default Setting object
  # by using defaults specified here and those specified in the local config
  # mission may be nil.
  def self.build_default(mission:)
    setting = new(mission: mission)
    if mission.present?
      KEYS_TO_COPY_FROM_ROOT.each { |k| setting[k] = root[k] }
      setting.generate_incoming_sms_token
    end
    setting
  end

  def self.theme_exists?
    # TODO: refactor to get this path from the Themeing system.
    File.exist?(Rails.root.join("app/assets/stylesheets/all/themes/_custom_theme.scss"))
  end

  def self.theme_options
    options = [%w[NEMO nemo], %w[ELMO elmo]]
    options << [I18n.t("common.custom"), "custom"] if theme_exists?
    options
  end

  def generate_override_code!(size = 6)
    self.override_code = Random.alphanum_no_zero(size)
    save!
  end

  def generate_incoming_sms_token(replace = false)
    # Don't replace token unless replace==true
    return unless incoming_sms_token.nil? || replace

    # Ensure that the new token is actually different
    new_token = nil
    loop do
      new_token = SecureRandom.hex
      break unless new_token == incoming_sms_token
    end

    self.incoming_sms_token = new_token
  end

  def regenerate_incoming_sms_token!
    generate_incoming_sms_token(true)
    save!
  end

  # converts preferred_locales to a comma delimited string
  def preferred_locales_str
    (preferred_locales || []).join(",")
  end

  def preferred_locales_str=(codes)
    self.preferred_locales = (codes || "").split(",")
  end

  # converts preferred locales to symbols on read
  def preferred_locales
    locales = self["preferred_locales"]
    locales.map(&:to_sym)
  end

  def default_locale
    preferred_locales.first
  end

  def incoming_sms_numbers_str
    incoming_sms_numbers.join(", ")
  end

  def incoming_sms_numbers_str=(nums)
    self.incoming_sms_numbers = (nums || "").split(",").map { |n| PhoneNormalizer.normalize(n) }.compact
  end

  # This method converts the hash in the database for display in the browser.
  def generic_sms_config_str
    @generic_sms_config_str ||
      if generic_sms_config.present?
        JSON.pretty_generate(generic_sms_config)
      else
        ""
      end
  end

  # Determines if this setting is read only due to mission being locked.
  def read_only?
    mission&.locked? # Mission may be nil if admin mode, in which case it's not read only.
  end

  def site_name
    Cnfg.site_name(theme)
  end

  def site_email_with_name
    Cnfg.site_email_with_name(theme)
  end

  private

  # gets rid of any junk chars in locales
  def normalize_locales
    self.preferred_locales = preferred_locales.map { |l| l.to_s.downcase.gsub(/[^a-z]/, "")[0, 2] }
    true
  end

  def normalize_twilio_phone_number
    # Allow for the use of a database that hasn't had the migration run
    return unless respond_to?(:twilio_phone_number)

    self.twilio_phone_number = PhoneNormalizer.normalize(twilio_phone_number)
  end

  def normalize_incoming_sms_numbers
    # Most normalization is performed in the assignment method.
    # Here we just ensure no nulls.
    self.incoming_sms_numbers = [] if incoming_sms_numbers.blank?
  end

  def jsonify_generic_sms_config
    return if @generic_sms_config_str.blank?
    self.generic_sms_config = JSON.parse(@generic_sms_config_str)
  rescue JSON::ParserError => e
    self.generic_sms_json_error = e.to_s
  end

  # makes sure all language codes are valid ISO639 codes
  def locales_are_valid
    preferred_locales.each do |l|
      errors.add(:preferred_locales_str, :invalid_code, code: l) unless ISO_639.find(l.to_s)
    end
  end

  # makes sure at least one of the chosen locales is an available locale
  def one_locale_must_have_translations
    return unless (preferred_locales & I18n.available_locales).empty?
    errors.add(:preferred_locales_str, :one_must_have_translations,
      locales: I18n.available_locales.join(","))
  end

  # sms adapter can be blank or must be valid according to the Factory
  def sms_adapter_is_valid
    errors.add(:default_outgoing_sms_adapter, :is_invalid) unless default_outgoing_sms_adapter.blank? ||
      Sms::Adapters::Factory.name_is_valid?(default_outgoing_sms_adapter)
  end

  # check if settings for a particular adapter should be validated
  def should_validate?(adapter)
    # settings for the default outgoing adapter should always be validated
    return true if default_outgoing_sms_adapter == adapter

    # settings for an adapter should be validated if any settings for that adapter are present
    case adapter
    when "Twilio"
      twilio_phone_number.present? || twilio_account_sid.present? || twilio_auth_token1.present?
    when "FrontlineCloud"
      frontlinecloud_api_key.present?
    end
  end

  # checks that the provided credentials are valid
  def sms_credentials_are_valid
    validate_twilio if should_validate?("Twilio")
    validate_frontline_cloud if should_validate?("FrontlineCloud")
  end

  def validate_twilio
    errors.add(:twilio_account_sid, :blank) if twilio_account_sid.blank?
    errors.add(:twilio_auth_token1, :blank) if twilio_auth_token.blank? && twilio_auth_token1.blank?
  end

  def generic_sms_valid_json
    # JSON error flag would have been set in before_validation callback if invalid
    errors.add(:generic_sms_config_str, :invalid_json, msg: generic_sms_json_error) if generic_sms_json_error
  end

  def generic_sms_valid_keys
    return if generic_sms_config.nil?
    return if generic_sms_config.is_a?(Hash) &&
      (generic_sms_config.keys - Sms::Adapters::GenericAdapter::VALID_KEYS).empty?
    errors.add(:generic_sms_config_str, :invalid_keys)
  end

  def generic_sms_required_keys
    return if generic_sms_config.nil?
    Sms::Adapters::GenericAdapter::REQUIRED_KEYS.each do |full_key|
      value = full_key.split(".").inject(generic_sms_config) do |memo, key|
        memo.is_a?(Hash) ? memo[key] : nil
      end
      errors.add(:generic_sms_config_str, :missing_keys) && break if value.nil?
    end
  end

  def validate_frontline_cloud
    return unless frontlinecloud_api_key.blank? && frontlinecloud_api_key1.blank?
    errors.add(:frontlinecloud_api_key1, :blank)
  end

  # clear SMS fields if requested
  def clear_sms_fields_if_requested
    if clear_twilio == "1"
      self.twilio_phone_number = nil
      self.twilio_account_sid = nil
      self.twilio_auth_token = nil
      self.twilio_auth_token1 = nil
    end
    self.frontlinecloud_api_key = nil if clear_frontlinecloud == "1"
  end

  # if the sms credentials temp fields are set (and they match, which is checked above),
  # copy the value to the real field
  def save_sms_credentials
    self.twilio_auth_token = twilio_auth_token1 if twilio_auth_token1.present?
    self.frontlinecloud_api_key = frontlinecloud_api_key1 if frontlinecloud_api_key1.present?
    true
  end
end
