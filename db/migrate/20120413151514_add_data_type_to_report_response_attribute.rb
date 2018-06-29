class AddDataTypeToReportResponseAttribute < ActiveRecord::Migration[4.2]
  def change
    add_column :report_response_attributes, :data_type, :string
  end
end
