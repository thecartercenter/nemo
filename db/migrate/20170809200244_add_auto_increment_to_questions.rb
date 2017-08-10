class AddAutoIncrementToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :auto_increment, :boolean, default: false, null: false
  end
end
