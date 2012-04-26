class AddDataTypeToReportResponseAttribute < ActiveRecord::Migration
  def change
    add_column :report_response_attributes, :data_type, :string
  end
end
