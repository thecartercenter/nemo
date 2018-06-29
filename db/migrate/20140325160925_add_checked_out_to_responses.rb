class AddCheckedOutToResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :checked_out_at, :timestamp
    add_index  :responses, :checked_out_at

    add_column :responses, :checked_out_by_id, :integer
    add_foreign_key :responses, :users, :column => 'checked_out_by_id'
  end
end
