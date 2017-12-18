class RemoveConditionForeignKey < ActiveRecord::Migration
  def up
    remove_foreign_key "conditions", column: "conditionable_id"
  end
end
