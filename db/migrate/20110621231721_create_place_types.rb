class CreatePlaceTypes < ActiveRecord::Migration
  def self.up
    create_table :place_types do |t|
      t.string :name
      t.integer :level

      t.timestamps
    end
    PlaceType.create(:name => "Country", :level => 1)
    PlaceType.create(:name => "State/Province", :level => 2)
    PlaceType.create(:name => "Municipality", :level => 3)
    PlaceType.create(:name => "Address/Landmark", :level => 4)
  end

  def self.down
    drop_table :place_types
  end
end
