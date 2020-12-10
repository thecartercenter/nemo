# frozen_string_literal: true

class AddPreloadLastSavedToFormItems < ActiveRecord::Migration[6.0]
  def change
    add_column :form_items, :preload_last_saved, :boolean, default: false, null: false
  end
end
