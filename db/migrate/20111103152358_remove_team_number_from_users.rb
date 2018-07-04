class RemoveTeamNumberFromUsers < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :users, :team_number
  end

  def self.down
    add_column :users, :team_number, :string
  end
end
