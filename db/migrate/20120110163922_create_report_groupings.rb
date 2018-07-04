class CreateReportGroupings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :report_groupings do |t|
      t.string :type
      t.string :name
      t.string :code
      t.string :join_tables
      t.integer :question_id

      t.timestamps
    end
  end

  def self.down
    drop_table :report_groupings
  end
end
