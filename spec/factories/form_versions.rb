# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: form_versions
#
#  id         :uuid             not null, primary key
#  code       :string(255)      not null
#  current    :boolean          default(TRUE), not null
#  minimum    :boolean          default(TRUE), not null
#  number     :string(10)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  form_id    :uuid             not null
#
# Indexes
#
#  index_form_versions_on_code                (code) UNIQUE
#  index_form_versions_on_form_id             (form_id)
#  index_form_versions_on_form_id_and_number  (form_id,number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (form_id => forms.id)
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :form_version do
    form
  end
end
