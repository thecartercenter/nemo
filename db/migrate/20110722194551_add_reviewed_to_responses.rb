class AddReviewedToResponses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :responses, :reviewed, :boolean
  end

  def self.down
    remove_column :responses, :reviewed
  end
end
