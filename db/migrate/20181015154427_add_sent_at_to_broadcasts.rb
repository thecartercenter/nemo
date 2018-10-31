# frozen_string_literal: true

class AddSentAtToBroadcasts < ActiveRecord::Migration[5.1]
  def change
    add_column(:broadcasts, :sent_at, :timestamp)
  end
end
