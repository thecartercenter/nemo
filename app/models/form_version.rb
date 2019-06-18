# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: form_versions
#
#  id         :uuid             not null, primary key
#  code       :string(255)      not null
#  is_current :boolean          default(TRUE), not null
#  sequence   :integer          default(1), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  form_id    :uuid             not null
#
# Indexes
#
#  index_form_versions_on_code     (code) UNIQUE
#  index_form_versions_on_form_id  (form_id)
#
# Foreign Keys
#
#  form_versions_form_id_fkey  (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

# models a version number for a Form object. allows forms to have multiple uniquely identifiable versions.
# provides 3 letter code for use with sms encoded forms.
class FormVersion < ApplicationRecord
  belongs_to :form

  after_initialize :generate_code
  before_create :ensure_unique_code

  scope :current, -> { where(is_current: true) }

  delegate :mission, to: :form

  CODE_LENGTH = 3

  # inits a new FormVersion with same form_id
  # increments sequence
  # sets self.is_current = false
  def upgrade!
    upgraded = self.class.new(form_id: form_id, is_current: true)
    self.is_current = false
    save
    upgraded.save!
    upgraded
  end

  private

  # generates the unique random code
  def generate_code
    # only need to do this if code not set
    return if code
    ensure_unique_code
  end

  # double checks that code is still unique
  def ensure_unique_code
    # keep trying new random codes until no match
    while self.class.find_by(code: self.code = Random.letters(CODE_LENGTH)); end
    true
  end
end
