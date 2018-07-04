class AddGroupInstanceToAnswer < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :group_instance, :integer
  end
end
