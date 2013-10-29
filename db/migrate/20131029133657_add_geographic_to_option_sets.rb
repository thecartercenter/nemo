class AddGeographicToOptionSets < ActiveRecord::Migration
  def change
    add_column :option_sets, :geographic, :boolean, :null => false, :default => false
    add_index :option_sets, :geographic
  end
end
