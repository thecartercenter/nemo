class RemovePaperclipNullConstraints < ActiveRecord::Migration[6.0]
  def up
    change_column_null :media_objects, :item_content_type, true
    change_column_null :media_objects, :item_file_name, true
    change_column_null :media_objects, :item_file_size, true
    change_column_null :media_objects, :item_updated_at, true

    change_column_null :saved_uploads, :file_content_type, true
    change_column_null :saved_uploads, :file_file_name, true
    change_column_null :saved_uploads, :file_file_size, true
    change_column_null :saved_uploads, :file_updated_at, true
  end

  def down
    # Reverting will fail if any null data has been added since migrating.
  end
end
