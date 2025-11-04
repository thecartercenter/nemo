class RemoveOldSmsStuff < ActiveRecord::Migration[4.2]
  def up
    begin
      drop_table :sms_codes
    rescue StandardError
      nil
    end
    begin
      drop_table :sms_responses
    rescue StandardError
      nil
    end
    begin
      remove_column :options, :sms_code
    rescue StandardError
      nil
    end
    begin
      remove_column :questions, :sms_question_no
    rescue StandardError
      nil
    end
  end

  def down
  end
end
