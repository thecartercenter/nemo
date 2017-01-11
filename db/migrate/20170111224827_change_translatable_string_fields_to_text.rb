class ChangeTranslatableStringFieldsToText < ActiveRecord::Migration
  def up
    change_column :form_items, :group_name_translations, :text
    change_column :form_items, :group_hint_translations, :text
  end

  def down
    change_column :form_items, :group_name_translations, :string
    change_column :form_items, :group_hint_translations, :string
  end
end
