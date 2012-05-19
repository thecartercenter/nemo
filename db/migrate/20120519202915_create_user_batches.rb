class CreateUserBatches < ActiveRecord::Migration
  def change
    create_table :user_batches do |t|
      t.text :users

      t.timestamps
    end
  end
end
