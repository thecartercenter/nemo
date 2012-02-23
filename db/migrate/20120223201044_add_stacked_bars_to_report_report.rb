class AddStackedBarsToReportReport < ActiveRecord::Migration
  def change
    add_column :report_reports, :bar_style, :string, :default => "Side By Side"
  end
end
