class AddTypeToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :type, :string, null: false, default: "Answer"
  end
end
