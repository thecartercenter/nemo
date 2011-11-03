class RemoveTeamNumberFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :team_number
  end

  def self.down
    add_column :users, :team_number, :string
  end
end
