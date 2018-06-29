class AddChoiceForeignKey < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key "choices", "answers" rescue "No key to remove..."
    add_foreign_key "choices", "answers"
  end
end
