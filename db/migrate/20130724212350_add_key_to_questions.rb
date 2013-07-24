class AddKeyToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :key, :boolean, :default => false
  end
end
