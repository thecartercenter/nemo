# frozen_string_literal: true

# Add error message column to Sms Messages
class AddErrorMessageToSmsMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :sms_messages, :error_message, :string
  end
end
