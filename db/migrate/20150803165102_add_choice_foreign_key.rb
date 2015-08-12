class AddChoiceForeignKey < ActiveRecord::Migration
  def change
    remove_foreign_key "choices", "answers" rescue "No key to remove..."
    add_foreign_key "choices", "answers"
  end
end
