class DisableSmsAuthenticationOnForms < ActiveRecord::Migration[4.2]
  def up
    Form.update_all(authenticate_sms: false)
  end

  def down
    Form.update_all(authenticate_sms: true)
  end
end
