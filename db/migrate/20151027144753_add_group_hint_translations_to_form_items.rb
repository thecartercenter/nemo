class AddGroupHintTranslationsToFormItems < ActiveRecord::Migration[4.2]
  def change
    add_column :form_items, :group_hint_translations, :string
  end
end
