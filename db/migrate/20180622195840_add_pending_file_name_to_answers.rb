class AddPendingFileNameToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :pending_file_name, :string
  end
end
