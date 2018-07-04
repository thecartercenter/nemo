class AddMissionIdToJoinClasses < ActiveRecord::Migration[4.2]
  def change
    add_column(:optionings, :mission_id, :integer)
    add_column(:questionings, :mission_id, :integer)
    add_column(:conditions, :mission_id, :integer)

    add_foreign_key "optionings", "missions"
    add_foreign_key "questionings", "missions"
    add_foreign_key "conditions", "missions"
  end
end
