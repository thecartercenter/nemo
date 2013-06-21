class AddMissionIdToSmsMessages < ActiveRecord::Migration
  def change
    add_column :sms_messages, :mission_id, :integer
  end
end
