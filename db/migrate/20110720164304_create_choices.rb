class CreateChoices < ActiveRecord::Migration[4.2]
  def self.up
    create_table :choices do |t|
      t.integer :answer_id
      t.integer :option_id

      t.timestamps
    end

    Answer.includes({questioning: {question: :type} }).each do |a|
      # if this is an answer for a select_multiple, create a new choice object and set option_id to nil
      type = a.questioning.question.type.name rescue nil
      if type == "select_multiple"
        Choice.create(:answer_id => a.id, :option_id => a.option_id)
        a.option_id = nil
        a.save
      end
    end
  end

  def self.down
    drop_table :choices
  end
end
