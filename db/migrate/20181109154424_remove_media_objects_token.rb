# frozen_string_literal: true

class RemoveMediaObjectsToken < ActiveRecord::Migration[5.1]
  def up
    remove_column(:media_objects, :token)
  end

  def down
    add_column(:media_objects, :token, :string)
  end
end
