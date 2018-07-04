class AddValueCodeToReportResponseAttribute < ActiveRecord::Migration[4.2]
  def change
    add_column :report_response_attributes, :value_code, :string
  end
end
