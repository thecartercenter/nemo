class AddKeyToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :key, :boolean, :default => false
  end
end
