class AddAlternatePhoneNumbers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :phone2, :string
  end

  def down
    remove_column :users, :phone2
  end
end
