class AddMissionIdToSmsMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :sms_messages, :mission_id, :integer
  end
end
