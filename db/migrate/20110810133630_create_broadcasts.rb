class CreateBroadcasts < ActiveRecord::Migration[4.2]
  def self.up
    create_table :broadcasts do |t|
      t.string :subject
      t.text :body
      t.string :medium
      t.text :send_errors

      t.timestamps
    end
  end

  def self.down
    drop_table :broadcasts
  end
end
