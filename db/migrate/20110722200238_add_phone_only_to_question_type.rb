class AddPhoneOnlyToQuestionType < ActiveRecord::Migration
  def self.up
    add_column :question_types, :phone_only, :boolean
  end

  def self.down
    remove_column :question_types, :phone_only
  end
end
