class RemoveSingleAccessTokenFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :single_access_token
  end
end
