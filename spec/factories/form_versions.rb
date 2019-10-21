# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: form_versions
#
#  id         :uuid             not null, primary key
#  code       :string(255)      not null
#  is_current :boolean          default(TRUE), not null
#  number     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  form_id    :uuid             not null
#
# Indexes
#
#  index_form_versions_on_code     (code) UNIQUE
#  index_form_versions_on_form_id  (form_id)
#  index_form_versions_on_number   (number) UNIQUE
#
# Foreign Keys
#
#  form_versions_form_id_fkey  (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

FactoryGirl.define do
  factory :form_version do
    form
  end
end
