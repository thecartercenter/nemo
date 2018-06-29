class AddCompactNameIndexToMissions < ActiveRecord::Migration[4.2]
  def change
    add_index(:missions, [:compact_name])
  end
end
