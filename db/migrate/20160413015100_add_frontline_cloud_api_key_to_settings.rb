class AddFrontlineCloudAPIKeyToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :frontlinecloud_api_key, :string
  end
end
