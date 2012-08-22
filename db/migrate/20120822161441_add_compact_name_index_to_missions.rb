class AddCompactNameIndexToMissions < ActiveRecord::Migration
  def change
    add_index(:missions, [:compact_name])
  end
end
