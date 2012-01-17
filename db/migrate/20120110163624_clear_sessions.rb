class ClearSessions < ActiveRecord::Migration
  def self.up
    execute("DELETE FROM sessions")
  end

  def self.down
  end
end
