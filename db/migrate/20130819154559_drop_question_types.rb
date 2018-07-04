class DropQuestionTypes < ActiveRecord::Migration[4.2]
  def up
  	drop_table :question_types
  end

  def down
  end
end
