class AddOutgoingSmsLanguageToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :outgoing_sms_language, :string
  end
end
