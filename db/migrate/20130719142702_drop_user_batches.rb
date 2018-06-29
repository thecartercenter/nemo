class DropUserBatches < ActiveRecord::Migration[4.2]
  def up
    drop_table :user_batches
  end

  def down
  end
end
