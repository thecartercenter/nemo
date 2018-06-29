class CreateSettables < ActiveRecord::Migration[4.2]
  def self.up
    create_table :settables do |t|
      t.string :key
      t.string :name
      t.string :description
      t.string :default
      t.string :kind

      t.timestamps
    end
  end

  def self.down
    drop_table :settables
  end
end
