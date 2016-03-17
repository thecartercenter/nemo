class DisableSmsAuthenticationOnForms < ActiveRecord::Migration
  def up
    Form.update_all(authenticate_sms: false)
  end

  def down
    Form.update_all(authenticate_sms: true)
  end
end
