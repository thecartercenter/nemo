class AddAttachmentToOperations < ActiveRecord::Migration[5.1]
  def up
    add_attachment :operations, :attachment
  end

  def down
    remove_attachment :operations, :attachment
  end
end
