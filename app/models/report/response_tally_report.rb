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

class Report::ResponseTallyReport < Report::TallyReport
  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h
  end

  protected

  def prep_query(rel)
    # add tally to select
    rel = rel.select("COUNT(responses.id) AS tally")

    # add filter
    rel = apply_filter(rel)

    # add groupings
    rel = apply_groupings(rel)

    rel.limit(response_limit)
  end

  # applys both groupings
  def apply_groupings(rel, options = {})
    if pri_grouping && options[:secondary_only]
      raise Report::ReportError, "primary groupings not allowed for this report type"
    end
    rel = pri_grouping.apply(rel) if pri_grouping
    rel = sec_grouping.apply(rel) if sec_grouping
    rel
  end

  def has_grouping(which)
    grouping = which == :row ? pri_grouping : sec_grouping
    !grouping.nil?
  end

  def header_title(which)
    grouping = which == :row ? pri_grouping : sec_grouping
    grouping ? grouping.header_title : nil
  end

  def truncatable?
    true
  end

  private

  def grouping(rank)
    c = calculations.find_by(rank: rank)
    c.nil? ? nil : Report::Grouping.new(c, %i[primary secondary][rank - 1])
  end

  def pri_grouping
    @pri_grouping ||= grouping(1)
  end

  def sec_grouping
    @sec_grouping ||= grouping(2)
  end

  def response_limit
    # We do plus one and delete the one extra later so that we know if there are more than the limit.
    RESPONSES_QUANTITY_LIMIT + 1
  end
end
