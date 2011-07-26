class AddLongNameToQuestionTypes < ActiveRecord::Migration
  def self.up
    add_column :question_types, :long_name, :string
  end

  def self.down
    remove_column :question_types, :long_name
  end
end
