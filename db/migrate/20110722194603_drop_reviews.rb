class DropReviews < ActiveRecord::Migration
  def self.up
    drop_table :reviews
  end

  def self.down
  end
end
