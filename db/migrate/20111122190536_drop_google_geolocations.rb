class DropGoogleGeolocations < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :google_geolocations
  end

  def self.down
  end
end
