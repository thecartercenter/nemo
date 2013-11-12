# models a version number for a Form object. allows forms to have multiple uniquely identifiable versions.
# provides 3 letter code for use with sms encoded forms.
class FormVersion < ActiveRecord::Base
  attr_accessible :code, :form_id, :is_current, :sequence
  belongs_to :form

  after_initialize :generate_code
  before_create :ensure_unique_code

  CODE_LENGTH = 3

  # inits a new FormVersion with same form_id
  # increments sequence
  # sets self.is_current = false
  def upgrade
    upgraded = self.class.new(:form_id => form_id, :sequence => sequence + 1)
    self.is_current = false
    save
    return upgraded
  end

  def sequence_and_code
    "#{sequence} (#{code})"
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
      while self.class.find_by_code(self.code = Random.letters(CODE_LENGTH)); end
      return true
    end
end
