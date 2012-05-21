class AddWhichPhoneToBroadcasts < ActiveRecord::Migration
  def change
    add_column :broadcasts, :which_phone, :string
  end
end
