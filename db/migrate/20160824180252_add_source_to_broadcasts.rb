class AddSourceToBroadcasts < ActiveRecord::Migration
  def change
    add_column :broadcasts, :source, :string, default: 'manual', null: false, index: true
  end
end
