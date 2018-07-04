class AddLongNameToQuestionTypes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :question_types, :long_name, :string
  end

  def self.down
    remove_column :question_types, :long_name
  end
end
