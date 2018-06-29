class CreatePlaces < ActiveRecord::Migration[4.2]
  def self.up
    create_table :places do |t|
      t.string :long_name
      t.string :short_name
      t.string :full_name
      t.integer :place_type_id
      t.integer :container_id
      t.decimal :latitude, :precision => 20, :scale => 15
      t.decimal :longitude, :precision => 20, :scale => 15

      t.timestamps
    end
  end

  def self.down
    drop_table :places
  end
end
