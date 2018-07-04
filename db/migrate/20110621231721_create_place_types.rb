class CreatePlaceTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :place_types do |t|
      t.string :name
      t.integer :level

      t.timestamps
    end
  end

  def self.down
    drop_table :place_types
  end
end
