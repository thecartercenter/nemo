class AddIncomingSmsTokenToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :incoming_sms_token, :string

    Setting.transaction do
      Setting.where.not(mission_id: nil).each do |setting|
        setting.generate_incoming_sms_token(true)
        setting.save(validate: false)
      end
    end
  end
end
