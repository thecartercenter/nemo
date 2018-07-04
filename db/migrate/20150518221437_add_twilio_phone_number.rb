class AddTwilioPhoneNumber < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :twilio_phone_number, :string
  end
end
