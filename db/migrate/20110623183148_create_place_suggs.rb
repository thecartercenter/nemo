class CreatePlaceSuggs < ActiveRecord::Migration[4.2]
  def self.up
    create_table :place_suggs do |t|
      t.integer :place_lookup_id
      t.integer :place_id
      t.integer :google_geolocation_id

      t.timestamps
    end
  end

  def self.down
    drop_table :place_suggs
  end
end
