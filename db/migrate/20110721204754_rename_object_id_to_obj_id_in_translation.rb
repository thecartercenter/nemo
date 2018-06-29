class RenameObjectIdToObjIdInTranslation < ActiveRecord::Migration[4.2]
  def self.up
    rename_column(:translations, :object_id, :obj_id)
  end

  def self.down
  end
end
