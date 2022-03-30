# frozen_string_literal: true

class AddTempProcessedToResponses < ActiveRecord::Migration[6.1]
  def up
    # Temporary column to specify whether response re-processing has happened yet.
    add_column :responses, :temp_processed, :boolean, default: false
  end
end
