class UserCurrentLoginAt < ActiveRecord::Migration
  def change
    add_column :users, :current_login_at, :datetime
  end
end
