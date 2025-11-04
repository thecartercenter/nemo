class AddMissionIdStandardIdKeys < ActiveRecord::Migration[4.2]
  def up
    # these indices enforce that you can only have one copy of a standard object per mission
    add_index(:forms, %i[mission_id standard_id], unique: true)
    add_index(:questions, %i[mission_id standard_id], unique: true)
    add_index(:option_sets, %i[mission_id standard_id], unique: true)
    add_index(:options, %i[mission_id standard_id], unique: true)
    add_index(:questionings, %i[mission_id standard_id], unique: true)
    add_index(:conditions, %i[mission_id standard_id], unique: true)
    add_index(:optionings, %i[mission_id standard_id], unique: true)
  end

  def down
  end
end
