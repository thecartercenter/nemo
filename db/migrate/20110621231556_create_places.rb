class CreatePlaces < ActiveRecord::Migration
  def self.up
    create_table :places do |t|
      t.string :name
      t.string :short_name
      t.integer :place_type_id
      t.integer :is_in_id
      t.decimal :lat, :precision => 20, :scale => 15
      t.decimal :lng, :precision => 20, :scale => 15
      
      t.timestamps
    end
  end

  def self.down
    drop_table :places
  end
end
