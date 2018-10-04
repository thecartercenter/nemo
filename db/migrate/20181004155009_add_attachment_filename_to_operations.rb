class AddAttachmentFilenameToOperations < ActiveRecord::Migration[5.1]
  def up
    add_column :operations, :attachment_filename, :string
  end

  def down
    remove_column :operations, :attachment_filename
  end
end
