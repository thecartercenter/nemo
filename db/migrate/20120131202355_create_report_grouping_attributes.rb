class CreateReportGroupingAttributes < ActiveRecord::Migration
  def change
    create_table :report_grouping_attributes do |t|
      t.string :name
      t.string :code
      t.string :join_tables

      t.timestamps
    end
  end
end
