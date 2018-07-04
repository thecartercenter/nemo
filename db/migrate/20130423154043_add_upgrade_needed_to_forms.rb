class AddUpgradeNeededToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :upgrade_needed, :boolean, :default => false
  end
end
