class AddPhoneOnlyToQuestionType < ActiveRecord::Migration[4.2]
  def self.up
    add_column :question_types, :phone_only, :boolean
  end

  def self.down
    remove_column :question_types, :phone_only
  end
end
