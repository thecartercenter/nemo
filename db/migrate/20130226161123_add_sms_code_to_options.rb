class AddSmsCodeToOptions < ActiveRecord::Migration
  def change
    add_column :options, :sms_code, :string
  end
end
