class AddIncomingSmsTokenToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :incoming_sms_token, :string

    Setting.transaction do
      Setting.where.not(mission_id: nil).each do |setting|
        setting.regenerate_incoming_sms_token!
      end
    end
  end
end
