# frozen_string_literal: true

class AddUrlToOperations < ActiveRecord::Migration[5.1]
  def up
    add_column(:operations, :url, :string)
  end

  def down
    remove_column(:operations, :url)
  end
end
