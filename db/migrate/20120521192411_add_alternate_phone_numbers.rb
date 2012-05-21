class AddAlternatePhoneNumbers < ActiveRecord::Migration
  def up
    add_column :users, :phone2, :string
  end

  def down
    remove_column :users, :phone2
  end
end
