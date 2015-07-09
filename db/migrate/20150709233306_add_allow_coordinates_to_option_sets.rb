class AddAllowCoordinatesToOptionSets < ActiveRecord::Migration
  def change
    add_column :option_sets, :allow_coordinates, :boolean, default: false, null: false
  end
end
