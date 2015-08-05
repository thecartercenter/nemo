class AddChoiceForeignKey < ActiveRecord::Migration
  def change
    add_foreign_key "choices", "answers"
  end
end
