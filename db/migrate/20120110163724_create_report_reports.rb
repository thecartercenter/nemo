class CreateReportReports < ActiveRecord::Migration[4.2]
  def self.up
    create_table :report_reports do |t|
      t.string :type
      t.string :name
      t.boolean :saved, :default => false
      t.integer :filter_id
      t.integer :pri_grouping_id
      t.integer :sec_grouping_id
      t.integer :calculation_id
      t.integer :aggregation_id

      t.timestamps
    end
  end

  def self.down
    drop_table :report_reports
  end
end
