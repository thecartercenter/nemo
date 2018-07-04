class AddGenericSmsConfigToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :generic_sms_config, :jsonb
  end
end
