class CreateQuestionTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :question_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :question_types
  end
end
