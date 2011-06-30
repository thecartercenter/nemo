class AddOdkNameToQuestionTypes < ActiveRecord::Migration
  def self.up
    add_column :question_types, :odk_name, :string
  end

  def self.down
    remove_column :question_types, :odk_name
  end
end
