class RenameReportFieldsAttribName < ActiveRecord::Migration
  def up
    remove_column :report_fields, :attrib_name
    add_column :report_fields, :attrib_id, :integer
  end

  def down
    add_column :report_fields, :attrib_name, :string
    remove_column :report_fields, :attrib_id
  end
end
