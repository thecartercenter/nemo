class AddTokenToMediaObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :media_objects, :token, :string
  end
end
