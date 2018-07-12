# frozen_string_literal: true

class AddPendingFileNameToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :pending_file_name, :string
  end
end
