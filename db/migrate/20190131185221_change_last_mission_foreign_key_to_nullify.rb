# frozen_string_literal: true

class ChangeLastMissionForeignKeyToNullify < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key "users", name: "users_last_mission_id_fkey"

    # on_update means what to do if the mission's ID changes. That shouldn't happen so we restrict.
    # on_delete means what to do if the mission is deleted. We can just nullify as this is not crucial data.
    add_foreign_key "users", "missions", column: "last_mission_id", name: "users_last_mission_id_fkey",
                                         on_update: :restrict, on_delete: :nullify
  end
end
