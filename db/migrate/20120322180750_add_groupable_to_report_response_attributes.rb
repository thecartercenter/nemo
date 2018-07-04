class AddGroupableToReportResponseAttributes < ActiveRecord::Migration[4.2]
  def change
    add_column :report_response_attributes, :groupable, :boolean, :default => false
  end
end
