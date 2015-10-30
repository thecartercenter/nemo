class AddGroupHintTranslationsToFormItems < ActiveRecord::Migration
  def change
    add_column :form_items, :group_hint_translations, :string
  end
end
