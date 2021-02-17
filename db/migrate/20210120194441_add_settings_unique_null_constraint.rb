# frozen_string_literal: true

class AddSettingsUniqueNullConstraint < ActiveRecord::Migration[6.0]
  def change
    add_index :settings, "(mission_id IS NULL)", where: "mission_id IS NULL", unique: true,
                                                 comment: "Ensures only one root setting"
  end
end
