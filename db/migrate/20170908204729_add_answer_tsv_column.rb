class AddAnswerTsvColumn < ActiveRecord::Migration
  def up
    add_column :answers, :tsv, :tsvector
  end
end
