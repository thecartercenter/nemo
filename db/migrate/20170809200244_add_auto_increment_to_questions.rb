class AddAutoIncrementToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :auto_increment, :boolean, default: false, null: false
  end
end
