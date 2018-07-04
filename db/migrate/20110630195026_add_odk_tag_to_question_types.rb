class AddOdkTagToQuestionTypes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :question_types, :odk_tag, :string
  end

  def self.down
    remove_column :question_types, :odk_tag
  end
end
