class DropUserBatches < ActiveRecord::Migration
  def up
    drop_table :user_batches
  end

  def down
  end
end
