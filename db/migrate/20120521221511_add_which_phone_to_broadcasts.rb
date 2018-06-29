class AddWhichPhoneToBroadcasts < ActiveRecord::Migration[4.2]
  def change
    add_column :broadcasts, :which_phone, :string
  end
end
