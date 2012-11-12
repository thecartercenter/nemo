class RemoveSecondCalculationFields < ActiveRecord::Migration
  def change
    remove_column :report_calculations, :attrib2_name
    remove_column :report_calculations, :question2_id
  end
end
