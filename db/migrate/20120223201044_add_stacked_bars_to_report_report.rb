class AddStackedBarsToReportReport < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :bar_style, :string, :default => "Side By Side"
  end
end
