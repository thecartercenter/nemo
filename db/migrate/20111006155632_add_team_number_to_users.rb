class AddTeamNumberToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :team_number, :string
  end

  def self.down
    remove_column :users, :team_number
  end
end
