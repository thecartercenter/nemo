# frozen_string_literal: true

class RemoveTempProcessedFromResponses < ActiveRecord::Migration[6.1]
  def up
    # Temporary column to specify whether response re-processing has happened yet.
    remove_column :responses, :temp_processed, :boolean, default: false
  end
end
