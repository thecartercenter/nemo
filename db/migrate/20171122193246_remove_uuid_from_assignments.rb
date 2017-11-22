class RemoveUuidFromAssignments < ActiveRecord::Migration
  def change
    remove_column :assignments, :uuid, :string
  end
end
