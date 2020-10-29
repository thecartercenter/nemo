# frozen_string_literal: true

# rubocop:disable Layout/LineLength
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
#  form_versions_form_id_fkey  (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# Models a version number for a Form object. Allows forms to have multiple uniquely identifiable versions.
# Provides unique 3-letter code for use with sms encoded forms,
# plus unique 10-character number for use with odk xml forms.
class FormVersion < ApplicationRecord
  belongs_to :form

  after_initialize :generate_code, :generate_number
  before_create :ensure_unique_code, :ensure_unique_number

  delegate :mission, to: :form

  CODE_LENGTH = 3

  private

  # Code is a series of random letters
  def generate_code
    return if code
    ensure_unique_code
  end

  # Number uses ODK convention: `yyyymmddrr` (last 2 characters are revision number)
  # https://docs.opendatakit.org/form-update/
  def generate_number
    return if number
    # Today's date with a revision of 00
    self.number = Time.current.strftime("%Y%m%d00")
    ensure_unique_number
  end

  def ensure_unique_code
    # keep trying new random codes until no match
    while self.class.find_by(code: (self.code = Random.letters(CODE_LENGTH))); end
  end

  def ensure_unique_number
    revision = number[-2, 2].to_i
    # Increment the revision number until no match
    while self.class.find_by(number: number)
      revision += 1
      raise RevisionTooHighError if revision >= 100
      self.number = number[0, 8] + revision.to_s.rjust(2, "0")
    end
  end
end
