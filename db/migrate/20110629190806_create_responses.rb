class CreateResponses < ActiveRecord::Migration[4.2]
  def self.up
    create_table :responses do |t|
      t.integer :form_id
      t.integer :user_id
      t.integer :location_id
      t.datetime :observed_at

      t.timestamps
    end
  end

  def self.down
    drop_table :responses
  end
end
