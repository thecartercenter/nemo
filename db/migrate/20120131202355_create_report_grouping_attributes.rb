class CreateReportGroupingAttributes < ActiveRecord::Migration[4.2]
  def change
    create_table :report_grouping_attributes do |t|
      t.string :name
      t.string :code
      t.string :join_tables

      t.timestamps
    end
  end
end
