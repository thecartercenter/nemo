class AddPreloadStuffToQuestionTypes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :question_types, :odk_preload, :string
    add_column :question_types, :odk_preload_params, :string
  end

  def self.down
    remove_column :question_types, :odk_preload_params
    remove_column :question_types, :odk_preload
  end
end
