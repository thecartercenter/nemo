# frozen_string_literal: true

class AddRequiredLevelsToFormItems < ActiveRecord::Migration[5.2]
  def change
    add_column :form_items, :all_levels_required, :boolean, null: false, default: false
  end
end
