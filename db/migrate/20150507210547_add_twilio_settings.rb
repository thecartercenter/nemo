class AddTwilioSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :twilio_account_sid, :string
    add_column :settings, :twilio_auth_token, :string
  end
end
