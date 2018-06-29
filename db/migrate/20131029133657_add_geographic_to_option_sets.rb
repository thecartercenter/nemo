class AddGeographicToOptionSets < ActiveRecord::Migration[4.2]
  def change
    add_column :option_sets, :geographic, :boolean, :null => false, :default => false
    add_index :option_sets, :geographic
  end
end
