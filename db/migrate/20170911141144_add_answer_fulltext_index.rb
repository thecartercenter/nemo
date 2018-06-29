class AddAnswerFulltextIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :answers, :tsv, using: "gin"
  end
end
