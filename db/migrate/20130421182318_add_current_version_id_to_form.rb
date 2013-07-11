class AddCurrentVersionIdToForm < ActiveRecord::Migration
  def change
    add_column :forms, :current_version_id, :integer
  end
end
