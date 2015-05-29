class AddTwilioSettings < ActiveRecord::Migration
  def change
    add_column :settings, :twilio_account_sid, :string
    add_column :settings, :twilio_auth_token, :string
  end
end
