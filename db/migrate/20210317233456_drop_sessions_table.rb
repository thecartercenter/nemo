# frozen_string_literal: true

class DropSessionsTable < ActiveRecord::Migration[6.1]
  def up
    # Hasn't been used since ~2017.
    drop_table :sessions
  end

  def down
    create_table :sessions # rubocop:disable Rails/CreateTableWithTimestamps
  end
end
