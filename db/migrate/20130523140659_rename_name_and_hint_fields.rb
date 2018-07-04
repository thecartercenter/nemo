class RenameNameAndHintFields < ActiveRecord::Migration[4.2]
  def change
    rename_column :options, :name, :_name
    rename_column :options, :hint, :_hint
    rename_column :questions, :name, :_name
    rename_column :questions, :hint, :_hint
  end
end
