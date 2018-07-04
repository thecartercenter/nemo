class RenameQuestionablesToQuestions < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key :questionables, :option_level
    remove_foreign_key :questionables, :parent
    remove_column :questionables, :type
    remove_column :questionables, :parent_id
    remove_column :questionables, :option_level_id
    rename_table :questionables, :questions
  end

  def down
  end
end
