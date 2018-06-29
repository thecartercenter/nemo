class RemoveSingleAccessTokenFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :single_access_token
  end
end
