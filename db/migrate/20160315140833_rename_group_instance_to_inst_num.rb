class RenameGroupInstanceToInstNum < ActiveRecord::Migration[4.2]
  def change
    rename_column :answers, :group_instance, :inst_num
  end
end
