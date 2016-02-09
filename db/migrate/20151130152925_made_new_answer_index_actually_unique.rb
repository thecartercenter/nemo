class MadeNewAnswerIndexActuallyUnique < ActiveRecord::Migration
  def change
    remove_index :answers, [:response_id, :questioning_id, :rank]
    add_index :answers, [:response_id, :questioning_id, :rank], unique: true
  end
end
