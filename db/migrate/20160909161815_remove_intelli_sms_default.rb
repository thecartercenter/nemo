class RemoveIntelliSmsDefault < ActiveRecord::Migration
  def up
    Setting.where(default_outgoing_sms_adapter: "IntelliSms").update_all(default_outgoing_sms_adapter: nil)
  end

  def down
    # Not going to attempt to restore IntellSMS defaults
  end
end
