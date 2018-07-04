class AddAnswerForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key("answers", "responses")
    add_foreign_key("answers", "options")
    add_foreign_key("answers", "form_items", column: "questioning_id")
  end
end
