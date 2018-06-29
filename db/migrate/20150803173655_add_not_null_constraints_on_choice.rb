class AddNotNullConstraintsOnChoice < ActiveRecord::Migration[4.2]
  def change
    change_column_null :choices, :answer_id, false
    change_column_null :choices, :option_id, false
  end
end
