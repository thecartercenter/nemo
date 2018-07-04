class AddRankToReportCalculations < ActiveRecord::Migration[4.2]
  def change
    add_column :report_calculations, :rank, :integer
  end
end
