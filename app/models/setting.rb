class Setting < ActiveRecord::Base
  include MissionBased

  # attribs to copy to configatron
  KEYS_TO_COPY = %w(timezone preferred_locales intellisms_username intellisms_password isms_hostname isms_username isms_password incoming_sms_number)

  # these are the keys that make sense in admin mode
  ADMIN_MODE_KEYS = %w(timezone preferred_locales)

  DEFAULTS = {:timezone => "UTC", :preferred_locales => [:en]}

  scope(:by_mission, lambda{|m| where(:mission_id => m ? m.id : nil)})
  scope(:default, where(DEFAULTS))

  before_validation(:cleanup_locales)
  before_validation(:nullify_fields_if_these_are_admin_mode_settings)
  validate(:locales_are_valid)
  validate(:one_locale_must_have_translations)
  validate(:sms_adapter_is_valid)
  validate(:sms_credentials_are_valid)
  before_save(:save_sms_passwords)

  serialize :preferred_locales, JSON

  # accessors for password/password confirm fields
  attr_accessor :intellisms_password1, :intellisms_password2, :isms_password1, :isms_password2

  # loads the settings for the given mission (or nil mission/admin mode) into the configatron store
  # if the settings can't be found, a default setting is created and saved before being loaded
  def self.load_for_mission(mission)
    setting = by_mission(mission).first

    if !setting
      setting = build_default(mission)
      setting.save!
    end

    setting.load
    return setting
  end

  # loads the default settings without saving
  def self.load_default
    setting = build_default
    setting.load
    return setting
  end

  # builds and returns (but doesn't save) a default Setting object
  # by using the defaults specified in this file and those specified in the local config
  # mission may be nil.
  def self.build_default(mission = nil)
    # initialize a new setting object with default values
    setting = by_mission(mission).default.new

    # copy default_settings from configatron
    configatron.default_settings.configatron_keys.each do |k|
      setting.send("#{k}=", configatron.default_settings.send(k)) if setting.respond_to?("#{k}=")
    end

    setting
  end

  # copies this setting to configatron
  def load
    # build hash
    hsh = Hash[*KEYS_TO_COPY.collect{|k| [k.to_sym, send(k)]}.flatten(1)]

    # get class based on sms adapter setting; default to nil if setting is invalid
    hsh[:outgoing_sms_adapter] = begin
      Sms::Adapters::Factory.new.create(outgoing_sms_adapter)
    rescue ArgumentError
      nil
    end

    # set system timezone
    Time.zone = timezone

    # copy to configatron
    configatron.configure_from_hash(hsh)
  end

  # converts preferred_locales to a comma delimited string
  def preferred_locales_str
    (preferred_locales || []).join(',')
  end

  # reverse of self.lang_codes
  def preferred_locales_str=(codes)
    self.preferred_locales = (codes || '').split(',')
  end

  # converts preferred locales to symbols on read
  def preferred_locales
    read_attribute('preferred_locales').map(&:to_sym)
  end

  private

    # gets rid of any junk chars in locales
    def cleanup_locales
      self.preferred_locales = preferred_locales.map{|l| l.to_s.downcase.gsub(/[^a-z]/, "")[0,2]}
      return true
    end

    # makes sure all language codes are valid ISO639 codes
    def locales_are_valid
      preferred_locales.each do |l|
        errors.add(:preferred_locales_str, :invalid_code, :code => l) unless ISO_639.find(l.to_s)
      end
    end

    # makes sure at least one of the chosen locales is an available locale
    def one_locale_must_have_translations
      if (preferred_locales & configatron.full_locales).empty?
        errors.add(:preferred_locales_str, :one_must_have_translations, :locales => configatron.full_locales.join(","))
      end
    end

    # sms adapter can be blank or must be valid according to the Factory
    def sms_adapter_is_valid
      errors.add(:outgoing_sms_adapter, :is_invalid) unless outgoing_sms_adapter.blank? || Sms::Adapters::Factory.name_is_valid?(outgoing_sms_adapter)
    end

    # checks that the provided credentials are valid
    def sms_credentials_are_valid
      case outgoing_sms_adapter
      when "IntelliSms"
        errors.add(:intellisms_username, :blank) if intellisms_username.blank?
        errors.add(:intellisms_password1, :did_not_match) unless intellisms_password1 == intellisms_password2
      when "Isms"
        errors.add(:isms_hostname, :blank) if isms_hostname.blank?
        errors.add(:isms_username, :blank) if isms_username.blank?
        errors.add(:isms_password1, :did_not_match) unless isms_password1 == isms_password2
      else
        # if there is no adapter then don't need to check anything
      end
    end

    # if the sms password temp fields are set (and they match, which is checked above), copy the value to the real field
    def save_sms_passwords
      unless outgoing_sms_adapter.blank?
        adapter = outgoing_sms_adapter.downcase
        input = send("#{adapter}_password1")
        send("#{adapter}_password=", input) unless input.blank?
      end
      return true
    end

    # if we are in admin mode, then a bunch of fields don't make sense and should be null
    # make sure they are in fact null
    def nullify_fields_if_these_are_admin_mode_settings
      # if mission_id is nil, that means we're in admin mode
      if mission_id.nil?
        (attributes.keys - ADMIN_MODE_KEYS - %w(id created_at updated_at mission_id)).each{|a| self.send("#{a}=", nil)}
      end
    end
end
