class RemoveOldSmsStuff < ActiveRecord::Migration[4.2]
  def up
    drop_table :sms_codes rescue nil
    drop_table :sms_responses rescue nil
    remove_column :options, :sms_code rescue nil
    remove_column :questions, :sms_question_no rescue nil
  end

  def down
  end
end
