# frozen_string_literal: true

class RemoveResponsesCountFromForms < ActiveRecord::Migration[5.2]
  def change
    remove_column :forms, :responses_count, :integer
  end
end
