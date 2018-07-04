class DropQuestionTypeFields < ActiveRecord::Migration[4.2]
  def self.up
    remove_column(:question_types, :phone_only)
    remove_column(:question_types, :odk_preload)
    remove_column(:question_types, :odk_preload_params)
  end

  def self.down
  end
end
