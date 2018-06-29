class StandardizeBooleanNames < ActiveRecord::Migration[4.2]
  def self.up
    rename_column(:forms, :is_published, :published)
    rename_column(:languages, :is_active, :active)
    rename_column(:places, :is_incomplete, :incomplete)
    rename_column(:users, :is_mobile_phone, :phone_is_mobile)
  end

  def self.down
  end
end
