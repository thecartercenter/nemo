class AddResponseIndices < ActiveRecord::Migration[4.2]
  def change
    add_index :responses, [:created_at]
    add_index :responses, [:updated_at]
    add_index :responses, [:reviewed]
  end
end
