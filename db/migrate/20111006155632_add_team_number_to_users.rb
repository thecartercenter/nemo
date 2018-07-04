class AddTeamNumberToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :team_number, :string
  end

  def self.down
    remove_column :users, :team_number
  end
end
