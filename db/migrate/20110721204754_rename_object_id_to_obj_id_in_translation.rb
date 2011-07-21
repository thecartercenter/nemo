class RenameObjectIdToObjIdInTranslation < ActiveRecord::Migration
  def self.up
    rename_column(:translations, :object_id, :obj_id)
  end

  def self.down
  end
end
