class AddUpgradeNeededToForms < ActiveRecord::Migration
  def change
    add_column :forms, :upgrade_needed, :boolean, :default => false
  end
end
