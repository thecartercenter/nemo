class AddGenericSmsConfigToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :generic_sms_config, :jsonb
  end
end
