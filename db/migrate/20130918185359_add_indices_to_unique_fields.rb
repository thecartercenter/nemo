class AddIndicesToUniqueFields < ActiveRecord::Migration[4.2]
  def change
    add_index(:forms, [:mission_id, :name], :unique => true)
    add_index(:option_sets, [:mission_id, :name], :unique => true)
    add_index(:questions, [:mission_id, :code], :unique => true)
  end
end
