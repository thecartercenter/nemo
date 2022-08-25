# frozen_string_literal: true

class AddUserEditorPreference < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :editor_preference, :string
  end
end
