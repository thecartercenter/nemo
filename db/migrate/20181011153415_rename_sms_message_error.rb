# frozen_string_literal: true

class RenameSmsMessageError < ActiveRecord::Migration[5.1]
  def change
    rename_column(:sms_messages, :error_message, :reply_error_message)
  end
end
