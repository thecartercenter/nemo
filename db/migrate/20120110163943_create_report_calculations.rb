class CreateReportCalculations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :report_calculations do |t|
      t.string :name
      t.string :code
      t.string :constraints

      t.timestamps
    end
  end

  def self.down
    drop_table :report_calculations
  end
end
