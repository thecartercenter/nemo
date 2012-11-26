class AddRankToReportCalculations < ActiveRecord::Migration
  def change
    add_column :report_calculations, :rank, :integer
  end
end
