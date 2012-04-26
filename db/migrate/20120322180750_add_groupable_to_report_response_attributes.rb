class AddGroupableToReportResponseAttributes < ActiveRecord::Migration
  def change
    add_column :report_response_attributes, :groupable, :boolean, :default => false
  end
end
