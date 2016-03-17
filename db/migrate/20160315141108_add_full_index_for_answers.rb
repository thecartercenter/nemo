class AddFullIndexForAnswers < ActiveRecord::Migration
  def change
    add_index :answers, [:response_id, :questioning_id, :inst_num, :rank], name: "answers_full", unique: true
  end
end
