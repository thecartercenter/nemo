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

FactoryBot.define do
  factory :setting do
    timezone { "Saskatchewan" } # No DST!
    preferred_locales_str { "en" }
    default_outgoing_sms_adapter { "Twilio" }
    twilio_account_sid { "user" }
    twilio_auth_token { "pass" }
    incoming_sms_token { SecureRandom.hex }
    incoming_sms_numbers { [] }
  end
end
