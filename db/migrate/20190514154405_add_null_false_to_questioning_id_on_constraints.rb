# frozen_string_literal: true

class AddNullFalseToQuestioningIdOnConstraints < ActiveRecord::Migration[5.2]
  def change
    change_column_null :constraints, :questioning_id, false
  end
end
