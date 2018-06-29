class AddAllowCoordinatesToOptionSets < ActiveRecord::Migration[4.2]
  def change
    add_column :option_sets, :allow_coordinates, :boolean, default: false, null: false
  end
end
