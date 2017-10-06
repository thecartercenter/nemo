class AddAnswerFulltextIndex < ActiveRecord::Migration
  def change
    add_index :answers, :tsv, using: "gin"
  end
end
