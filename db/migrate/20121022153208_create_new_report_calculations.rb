class CreateNewReportCalculations < ActiveRecord::Migration
  def change
    create_table :report_calculations do |t|
      t.string :type
      t.integer :report_report_id
      t.integer :question1_id
      t.integer :question2_id
      t.string :attrib1_name
      t.string :attrib2_name

      t.timestamps
    end
  end
end
