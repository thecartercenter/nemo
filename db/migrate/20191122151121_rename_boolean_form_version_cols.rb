# frozen_string_literal: true

class RenameBooleanFormVersionCols < ActiveRecord::Migration[5.2]
  def change
    rename_column :form_versions, :is_current, :current
    rename_column :form_versions, :is_oldest_accepted, :minimum
  end
end
