class AddOdkTagToQuestionTypes < ActiveRecord::Migration
  def self.up
    add_column :question_types, :odk_tag, :string
  end

  def self.down
    remove_column :question_types, :odk_tag
  end
end
