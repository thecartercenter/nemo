class RemoveUserEmailUniqueKey < ActiveRecord::Migration
  def up
    remove_index :users, :email
    add_index :users, :email
  end
end
