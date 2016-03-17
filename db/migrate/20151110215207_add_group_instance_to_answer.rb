class AddGroupInstanceToAnswer < ActiveRecord::Migration
  def change
    add_column :answers, :group_instance, :integer
  end
end
