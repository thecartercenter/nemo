class AddOutgoingSmsLanguageToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :outgoing_sms_language, :string
  end
end
