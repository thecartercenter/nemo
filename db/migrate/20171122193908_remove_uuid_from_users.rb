class RemoveUuidFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :uuid, :string
  end
end
