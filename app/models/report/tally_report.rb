# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: report_reports
#
#  id               :uuid             not null, primary key
#  aggregation_name :string(255)
#  bar_style        :string(255)      default("side_by_side")
#  display_type     :string(255)      default("table")
#  filter           :text
#  group_by_tag     :boolean          default(FALSE), not null
#  name             :string(255)      not null
#  percent_type     :string(255)      default("none")
#  question_labels  :string(255)      default("title")
#  question_order   :string(255)      default("number"), not null
#  text_responses   :string(255)      default("all")
#  type             :string(255)      not null
#  unique_rows      :boolean          default(FALSE)
#  unreviewed       :boolean          default(FALSE)
#  view_count       :integer          default(0), not null
#  viewed_at        :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  creator_id       :uuid
#  disagg_qing_id   :uuid
#  form_id          :uuid
#  mission_id       :uuid             not null
#
# Indexes
#
#  index_report_reports_on_creator_id      (creator_id)
#  index_report_reports_on_disagg_qing_id  (disagg_qing_id)
#  index_report_reports_on_form_id         (form_id)
#  index_report_reports_on_mission_id      (mission_id)
#  index_report_reports_on_view_count      (view_count)
#
# Foreign Keys
#
#  report_reports_creator_id_fkey      (creator_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_disagg_qing_id_fkey  (disagg_qing_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_form_id_fkey         (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# Methods common to all tally reports.
class Report::TallyReport < Report::Report
  include Report::Gridable

  def as_json(options = {})
    h = super(options)
    h[:data] = @data
    h[:headers] = @header_set ? @header_set.headers : {}
    h[:can_total] = can_total?
    h
  end

  protected

  # extracts the row header values from the db_result object
  def get_row_header
    get_header(:row)
  end

  # extracts the col header values from the db_result object
  def get_col_header
    get_header(:col)
  end

  def get_header(type)
    prefix = type == :row ? "pri" : "sec"
    if has_grouping(type)
      unique = @db_result.extract_unique_tuples("#{prefix}_name", "#{prefix}_value", "#{prefix}_type")
      hashes = unique.collect do |tuple|
        {name: Report::Formatter.format(tuple[0], tuple[2], :header), key: tuple[0], sort_value: tuple[1]}
      end
    else
      hashes = [{name: I18n.t("report/report.tally"), key: "tally", sort_value: 0}]
    end
    Report::Header.new(title: header_title(type), cells: hashes)
  end

  # processes a row from the db_result by adding the contained data to the result
  def extract_data_from_row(db_row, _db_row_idx)
    # get row and column indices (for result table) by looking them up in the header list
    row_key = has_grouping(:row) ? db_row["pri_name"] : "tally"
    col_key = has_grouping(:col) ? db_row["sec_name"] : "tally"
    r, c = @header_set.find_indices(row: row_key, col: col_key)

    # set the matching cell value
    @data.set_cell(r, c, get_result_value(db_row))
  end

  # extracts and casts the result value from the given result row
  def get_result_value(row)
    # counts will always be integers so we just cast to integer
    row["tally"].to_i
  end

  # totaling is appropriate
  def can_total?
    true
  end

  def data_table_dimensions
    {rows: @header_set[:row].size, cols: @header_set[:col].size}
  end
end
