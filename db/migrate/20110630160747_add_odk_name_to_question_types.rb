class AddOdkNameToQuestionTypes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :question_types, :odk_name, :string
  end

  def self.down
    remove_column :question_types, :odk_name
  end
end
