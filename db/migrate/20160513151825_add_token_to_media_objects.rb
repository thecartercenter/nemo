class AddTokenToMediaObjects < ActiveRecord::Migration
  def change
    add_column :media_objects, :token, :string
  end
end
