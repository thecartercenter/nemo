# frozen_string_literal: true

class RenameStatusChangedAt < ActiveRecord::Migration[5.2]
  def change
    rename_column :forms, :status_changed_at, :published_changed_at
  end
end
