class AddReviewedToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :reviewed, :boolean
  end

  def self.down
    remove_column :responses, :reviewed
  end
end
