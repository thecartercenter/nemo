class AddRangeToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :minimum, :integer
    add_column :questions, :maximum, :integer
    add_column :questions, :maxstrictly, :boolean
    add_column :questions, :minstrictly, :boolean
  end
end
