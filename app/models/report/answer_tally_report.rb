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

class Report::AnswerTallyReport < Report::TallyReport
  # Called when related OptionSet (and OptionSetChoice) are destroyed.
  # Destroys self if there are no option sets left.
  def option_set_destroyed
    destroy if option_sets.empty?
  end

  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h[:option_set_choices_attributes] = option_set_choices
    h
  end

  protected

  def prep_query(rel)
    # Reports must have calculations or option set choices.
    if calculations.empty? && option_sets.empty?
      raise Report::ReportError,
        I18n.t("activerecord.errors.models.report/report.no_calc_or_opt_set", name: name)
    end

    joins = []

    # add tally to select
    rel = rel.select("COUNT(responses.id) AS tally")

    # add question grouping
    expr = question_labels == "title" ? "questions.name_translations" : "questions.code"
    rel = rel.select("#{expr} AS pri_name, #{expr} AS pri_value, 'text'::text AS pri_type")
    joins << :questions
    rel = rel.group(expr)

    # add answer grouping
    # if we have an option set, we don't use calculation objects
    if option_sets.empty?
      # get expression fragments
      # this could be optimized by grouping name/value/sort for each calculation type,
      # but i don't think it will impact performance much
      name_exprs = calculations.collect(&:name_expr)
      value_exprs = calculations.collect(&:value_expr)
      sort_exprs = calculations.collect(&:sort_expr)
      where_exprs = calculations.collect(&:where_expr)

      # build full expressions
      name_expr_sql = build_nested_if(name_exprs, where_exprs)
      value_expr_sql = build_nested_if(value_exprs, where_exprs)
      sort_expr_sql = build_nested_if(sort_exprs, where_exprs)

      # add the selects and groups
      rel = rel.select("#{name_expr_sql} AS sec_name, #{value_expr_sql} AS sec_value, " \
        "#{sort_expr_sql} AS sec_sort_value, 'text' AS sec_type")
      rel = rel.group("option_sets.name").group(name_expr_sql).group(value_expr_sql).group(sort_expr_sql)

      # add the unified wheres
      rel = rel.where("(" + where_exprs.collect(&:sql).join(" OR ") + ")")

      # sort by sort expression
      # Moved pri_value ahead of sec_sort_value to make this deterministic (hopefully).
      rel = rel.order("option_sets.name, pri_value, sec_sort_value")
    else
      # add name expression
      expr = "COALESCE(ao.name_translations, co.name_translations)"
      rel = rel.select("#{expr} AS sec_name")
      rel = rel.group(expr)

      # add value expression
      expr = "COALESCE(ans_opt_nodes.rank, ch_opt_nodes.rank)"
      rel = rel.select("#{expr} AS sec_value")
      rel = rel.group(expr)
      rel = rel.where("option_sets.id" => option_sets.collect(&:id))

      # type is just text
      rel = rel.select("'text' AS sec_type")

      # we order first by question name/code and then by option rank, which is the same as sec_value
      rel = rel.order("pri_value, sec_value")

    end

    # add joins to relation
    joins << :options << :choices << :option_sets
    rel = add_joins_to_relation(rel, joins)

    # apply filter
    rel = apply_filter(rel)

    filter_non_top_level_answers(rel)
  end

  def header_title(which)
    I18n.t("activerecord.models." + (which == :row ? "question" : "answer"), count: 2)
  end

  def has_grouping(_which)
    true
  end

  private

  # builds a nested SQL IF statement of the form IF(a, x, IF(b, y, IF(c, z, ...)))
  def build_nested_if(exprs, conds)
    if exprs.size == 1
      exprs.first.sql
    else
      rest = build_nested_if(exprs[1..], conds[1..])
      "(CASE WHEN (#{conds.first.sql}) THEN (#{exprs.first.sql}) ELSE #{rest} END)"
    end
  end

  def filter_non_top_level_answers(rel)
    rel.where("ans_opt_nodes.ancestry_depth IS NULL OR ans_opt_nodes.ancestry_depth <= 1")
  end
end
