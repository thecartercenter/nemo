# frozen_string_literal: true

class AddSentTimeToBroadcasts < ActiveRecord::Migration[5.1]
  def change
    add_column(:broadcasts, :sent_time, :timestamp)
  end
end
