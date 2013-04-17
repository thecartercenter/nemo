class AddHashandDuplicateToResponses < ActiveRecord::Migration
  def change
    add_column :responses, :hash, :string
    add_column :responses, :duplicate, :boolean
  end
end
