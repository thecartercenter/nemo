# frozen_string_literal: true

class RemoveCurrentVersionIdFromForms < ActiveRecord::Migration[5.2]
  def change
    remove_column(:forms, :current_version_id, :uuid)
  end
end
