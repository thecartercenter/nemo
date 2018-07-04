class CreateQuestionings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :questionings do |t|
      t.integer :question_id
      t.integer :form_id
      t.integer :rank
      t.boolean :required
      t.boolean :hidden

      t.timestamps
    end
  end

  def self.down
    drop_table :questionings
  end
end
