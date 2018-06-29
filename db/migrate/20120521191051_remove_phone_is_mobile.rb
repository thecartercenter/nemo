class RemovePhoneIsMobile < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :phone_is_mobile
  end

  def down
    add_column :users, :phone_is_mobile, :boolean
  end
end
