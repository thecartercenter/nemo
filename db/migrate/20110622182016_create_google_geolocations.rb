class CreateGoogleGeolocations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :google_geolocations do |t|
      t.string :full_name
      t.text :json
      t.integer :place_type_id
      t.decimal :latitude, :precision => 20, :scale => 15
      t.decimal :longitude, :precision => 20, :scale => 15
      t.string :formatted_addr

      t.timestamps
    end
  end

  def self.down
    drop_table :google_geolocations
  end
end
