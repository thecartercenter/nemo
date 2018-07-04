class RemoveConditionForeignKey < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key "conditions", column: "conditionable_id"
  end
end
