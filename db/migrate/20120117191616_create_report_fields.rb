class CreateReportFields < ActiveRecord::Migration[4.2]
  def self.up
    create_table :report_fields do |t|
      t.integer :report_report_id
      t.string :attrib_name
      t.integer :question_id
      t.integer :question_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :report_fields
  end
end
