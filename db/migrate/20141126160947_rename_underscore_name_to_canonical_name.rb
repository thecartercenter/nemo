class RenameUnderscoreNameToCanonicalName < ActiveRecord::Migration[4.2]
  def up
    rename_column :questions, :_name, :canonical_name
    remove_column :questions, :_hint # No longer needed
    rename_column :options, :_name, :canonical_name
  end

  def down
  end
end
