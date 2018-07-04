class AddSmsAuthCodeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :sms_auth_code, :string
    add_index :users, :sms_auth_code, unique: true
  end
end
