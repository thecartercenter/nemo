class AddTypeToAnswers < ActiveRecord::Migration
  def up
    add_column :answers, :type, :string
    Answer.update_all(type: "Answer")
    change_column :answers, :type, :string, null: false
  end

  def down
    remove_column :answers, :type
  end
end
