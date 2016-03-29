class AddOdkHashToResponses < ActiveRecord::Migration
  def change
    add_column :responses, :odk_hash, :string
    add_index :responses, :odk_hash, unique: true
  end
end
