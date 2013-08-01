class AddResponseIndices < ActiveRecord::Migration
  def change
    add_index :responses, [:created_at]
    add_index :responses, [:updated_at]
    add_index :responses, [:reviewed]
  end
end
