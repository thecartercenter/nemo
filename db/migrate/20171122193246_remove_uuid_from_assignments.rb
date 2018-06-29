class RemoveUuidFromAssignments < ActiveRecord::Migration[4.2]
  def change
    remove_column :assignments, :uuid, :string
  end
end
