class RemoveQuestioningsCountFromForms < ActiveRecord::Migration
  def up
    remove_column :forms, :questionings_count
  end

  def down
    add_column :forms, :questionings_count, :integer
  end
end
