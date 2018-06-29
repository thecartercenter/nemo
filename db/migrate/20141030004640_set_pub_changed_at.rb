class SetPubChangedAt < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE forms SET pub_changed_at = NOW() WHERE published = 1")
  end

  def down
  end
end
