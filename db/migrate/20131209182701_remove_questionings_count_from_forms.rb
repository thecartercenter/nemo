class RemoveQuestioningsCountFromForms < ActiveRecord::Migration[4.2]
  def up
    remove_column :forms, :questionings_count
  end

  def down
    add_column :forms, :questionings_count, :integer
  end
end
