class AddAttachmentItemToMediaObjects < ActiveRecord::Migration[4.2]
  def self.up
    change_table :media_objects do |t|
      t.attachment :item
    end
  end

  def self.down
    remove_attachment :media_objects, :item
  end
end
