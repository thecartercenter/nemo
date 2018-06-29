class CreateOptions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :options do |t|
      t.string :name
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :options
  end
end
