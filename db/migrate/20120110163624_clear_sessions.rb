class ClearSessions < ActiveRecord::Migration[4.2]
  def self.up
    execute("DELETE FROM sessions")
  end

  def self.down
  end
end
