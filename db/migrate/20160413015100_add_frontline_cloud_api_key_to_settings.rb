class AddFrontlineCloudAPIKeyToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :frontlinecloud_api_key, :string
  end
end
