# frozen_string_literal: true

class SetSentAtToBestGuessForOldBroadcasts < ActiveRecord::Migration[5.2]
  def up
    execute("UPDATE broadcasts SET sent_at = created_at WHERE sent_at IS NULL")
  end
end
