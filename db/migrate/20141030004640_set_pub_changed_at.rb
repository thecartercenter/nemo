class SetPubChangedAt < ActiveRecord::Migration
  def up
    execute("UPDATE forms SET pub_changed_at = NOW() WHERE published = 1")
  end

  def down
  end
end
