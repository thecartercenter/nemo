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
#  pref_lang         :string(255)      not null
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

# Serializes Users for multiple purposes.
class UserSerializer < ApplicationSerializer
  fields :id, :name
end
