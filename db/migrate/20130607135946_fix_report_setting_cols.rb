class FixReportSettingCols < ActiveRecord::Migration[4.2]
  def up
    Report::Report.all.each do |r|
      # convert values in the report display_type, bar_style, question_labels, and percent_type columns to be underscored values, which work as i18n keys
      %w(display_type bar_style question_labels percent_type).each do |col|
        r.send("#{col}=", r.send(col).underscore.gsub(" ", "_")) unless r.send(col).nil?
      end

      # fix any 'undefined' values in the bar_style col
      r.bar_style = "side_by_side" if r.bar_style == "undefined"

      # change any blank percent type to 'none'
      r.percent_type = "none" if r.percent_type.blank?

      r.save(:validate => false)
    end

    # fix default values
    change_column :report_reports, :display_type, :string, :default => "table"
    change_column :report_reports, :bar_style, :string, :default => "side_by_side"
    change_column :report_reports, :question_labels, :string, :default => "code"
    change_column :report_reports, :percent_type, :string, :default => "none"
  end

  def down
  end
end
