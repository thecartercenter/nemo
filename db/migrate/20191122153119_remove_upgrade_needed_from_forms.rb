class RemoveUpgradeNeededFromForms < ActiveRecord::Migration[5.2]
  def change
    remove_column :forms, :upgrade_needed, :boolean
  end
end
