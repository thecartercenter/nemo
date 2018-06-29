class CreatePlaceCreators < ActiveRecord::Migration[4.2]
  def self.up
    create_table :place_creators do |t|
      t.integer :place_id

      t.timestamps
    end
  end

  def self.down
    drop_table :place_creators
  end
end
