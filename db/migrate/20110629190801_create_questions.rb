class CreateQuestions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :questions do |t|
      t.string :code
      t.string :name
      t.integer :question_type_id
      t.integer :option_set_id

      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end
