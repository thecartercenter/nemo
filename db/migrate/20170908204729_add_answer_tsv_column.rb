class AddAnswerTsvColumn < ActiveRecord::Migration[4.2]
  def up
    add_column :answers, :tsv, :tsvector
  end
end
