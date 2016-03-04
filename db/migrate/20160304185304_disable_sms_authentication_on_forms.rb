class DisableSmsAuthenticationOnForms < ActiveRecord::Migration
  def up
    Form.find_each do |f|
      f.update_column(:authenticate_sms, false)
    end
  end

  def down
    Form.find_each do |f|
      f.update_column(:authenticate_sms, true)
    end
  end
end
