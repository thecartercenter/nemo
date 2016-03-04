class AddAuthenticateSmsToForms < ActiveRecord::Migration
  def change
    add_column :forms, :authenticate_sms, :boolean, default: true
  end
end
