class UserCurrentLoginAt < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_login_at, :datetime
  end
end
