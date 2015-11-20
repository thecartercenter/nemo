class AddGroupNumberToAnswer < ActiveRecord::Migration
  def change
    add_column :answers, :group_number, :integer
  end
end
