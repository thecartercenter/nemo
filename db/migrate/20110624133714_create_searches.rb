class CreateSearches < ActiveRecord::Migration[4.2]
  def self.up
    create_table :searches do |t|
      t.string :query
      t.string :class_name

      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
