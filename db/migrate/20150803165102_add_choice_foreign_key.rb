class AddChoiceForeignKey < ActiveRecord::Migration[4.2]
  def change
    begin
      remove_foreign_key "choices", "answers"
    rescue StandardError
      "No key to remove..."
    end
    add_foreign_key "choices", "answers"
  end
end
