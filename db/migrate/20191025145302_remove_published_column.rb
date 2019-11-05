# frozen_string_literal: true

class RemovePublishedColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :forms, :published, :boolean
  end
end
