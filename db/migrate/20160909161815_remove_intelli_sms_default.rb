class RemoveIntelliSmsDefault < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.execute(%{
      UPDATE settings SET default_outgoing_sms_adapter=NULL WHERE default_outgoing_sms_adapter="IntelliSms"
    })
  end

  def down
    # Not going to attempt to restore IntellSMS defaults
  end
end
