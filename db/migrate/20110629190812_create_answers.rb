class CreateAnswers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :answers do |t|
      t.integer :response_id
      t.integer :question_id
      t.integer :option_id
      t.text :value

      t.timestamps
    end
  end

  def self.down
    drop_table :answers
  end
end
