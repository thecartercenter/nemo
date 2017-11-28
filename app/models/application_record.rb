class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_initialize :generate_uuid, if: :new_record?

  def generate_uuid
    return unless self.class.columns_hash.has_key?("uuid")
    self.uuid ||= SecureRandom.uuid
  end
end
