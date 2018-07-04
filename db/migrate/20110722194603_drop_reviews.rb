class DropReviews < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :reviews
  end

  def self.down
  end
end
