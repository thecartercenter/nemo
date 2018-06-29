class RenameQuestionsToQuestionables < ActiveRecord::Migration[4.2]
  def up
    rename_table :questions, :questionables
    add_column :questionables, :type, :string, :null => false

    # ref to parent question for subqings
    add_column :questionables, :parent_id, :integer

    # ref to option level for subqings
    add_column :questionables, :option_level_id, :integer

    add_index :questionables, :type

    add_foreign_key :questionables, :questionables, :column => :parent_id
    add_foreign_key :questionables, :option_levels

    # all questionables are currently of type Question
    execute("UPDATE questionables SET type = 'Question'")
  end
end
