class AddValueCodeToReportResponseAttribute < ActiveRecord::Migration
  def change
    add_column :report_response_attributes, :value_code, :string
  end
end
