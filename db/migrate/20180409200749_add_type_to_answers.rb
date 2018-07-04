# frozen_string_literal: true

# Add Type to Answers
class AddTypeToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :type, :string, null: false, default: "Answer"
  end
end
