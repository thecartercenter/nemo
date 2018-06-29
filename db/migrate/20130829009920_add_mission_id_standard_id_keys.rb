class AddMissionIdStandardIdKeys < ActiveRecord::Migration[4.2]
  def up
    # these indices enforce that you can only have one copy of a standard object per mission
    add_index(:forms, [:mission_id, :standard_id], :unique => true)
    add_index(:questions, [:mission_id, :standard_id], :unique => true)
    add_index(:option_sets, [:mission_id, :standard_id], :unique => true)
    add_index(:options, [:mission_id, :standard_id], :unique => true)
    add_index(:questionings, [:mission_id, :standard_id], :unique => true)
    add_index(:conditions, [:mission_id, :standard_id], :unique => true)
    add_index(:optionings, [:mission_id, :standard_id], :unique => true)
  end

  def down
  end
end
