class AddGroupItemNameTranslationsToFormItems < ActiveRecord::Migration
  def change
    add_column :form_items, :group_item_name_translations, :jsonb, default: {}
  end
end
