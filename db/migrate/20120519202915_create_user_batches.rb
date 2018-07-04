class CreateUserBatches < ActiveRecord::Migration[4.2]
  def change
    create_table :user_batches do |t|
      t.text :users

      t.timestamps
    end
  end
end
