class AddSourceToBroadcasts < ActiveRecord::Migration[4.2]
  def change
    add_column :broadcasts, :source, :string, default: "manual", null: false
    add_index :broadcasts, :source
  end
end
