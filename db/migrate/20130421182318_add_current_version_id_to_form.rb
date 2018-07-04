class AddCurrentVersionIdToForm < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :current_version_id, :integer
  end
end
