class DropGoogleGeolocations < ActiveRecord::Migration
  def self.up
    drop_table :google_geolocations
  end

  def self.down
  end
end
