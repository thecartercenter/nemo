class DropQuestionTypes < ActiveRecord::Migration
  def up
  	drop_table :question_types
  end

  def down
  end
end
