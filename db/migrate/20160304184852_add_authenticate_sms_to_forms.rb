class AddAuthenticateSmsToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :authenticate_sms, :boolean, default: true
  end
end
