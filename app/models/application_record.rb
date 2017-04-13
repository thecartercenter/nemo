class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_initialize :generate_uuid, if: :new_record?

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
