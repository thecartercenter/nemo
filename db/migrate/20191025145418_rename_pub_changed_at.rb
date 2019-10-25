# frozen_string_literal: true

class RenamePubChangedAt < ActiveRecord::Migration[5.2]
  def change
    rename_column :forms, :pub_changed_at, :status_changed_at
  end
end
