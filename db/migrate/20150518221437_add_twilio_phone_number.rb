class AddTwilioPhoneNumber < ActiveRecord::Migration
  def change
    add_column :settings, :twilio_phone_number, :string
  end
end
