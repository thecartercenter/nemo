class RenameGroupInstanceToInstNum < ActiveRecord::Migration
  def change
    rename_column :answers, :group_instance, :inst_num
  end
end
