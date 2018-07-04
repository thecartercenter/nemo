class AddNewTranslationFields < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :name, :text
    add_column :questions, :hint, :text
    add_column :questions, :name_translations, :text
    add_column :questions, :hint_translations, :text
    add_column :options, :name, :string
    add_column :options, :hint, :text
    add_column :options, :name_translations, :text
    add_column :options, :hint_translations, :text
  end
end
