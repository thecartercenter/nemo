# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: report_calculations
#
#  id               :uuid             not null, primary key
#  attrib1_name     :string(255)
#  rank             :integer          default(1), not null
#  type             :string(255)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  question1_id     :uuid
#  report_report_id :uuid             not null
#
# Indexes
#
#  index_report_calculations_on_question1_id      (question1_id)
#  index_report_calculations_on_report_report_id  (report_report_id)
#
# Foreign Keys
#
#  report_calculations_question1_id_fkey      (question1_id => questions.id) ON DELETE => restrict ON UPDATE => restrict
#  report_calculations_report_report_id_fkey  (report_report_id => report_reports.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# A calculation that returns 0 if the answer value is 0 and 1 otherwise
class Report::ZeroNonzeroCalculation < Report::Calculation
  def name_expr
    @name_expr ||= Report::Expression.new(
      sql_tplt: "CASE WHEN CAST(__TBL_PFX__answers.value AS INTEGER) > 0 THEN 'One or More' ELSE 'Zero' END",
      name: "name",
      clause: :select,
      chunks: {tbl_pfx: table_prefix}
    )
  end

  def value_expr
    @value_expr ||= Report::Expression.new(
      sql_tplt: "CASE WHEN CAST(__TBL_PFX__answers.value AS INTEGER) > 0 THEN 1 ELSE 0 END",
      name: "value",
      clause: :select,
      chunks: {tbl_pfx: table_prefix}
    )
  end

  def sort_expr
    @sort_expr ||= Report::Expression.new(
      sql_tplt: "CASE WHEN CAST(__TBL_PFX__answers.value AS INTEGER) > 0 THEN 1 ELSE 0 END",
      name: "sort",
      clause: :select,
      chunks: {tbl_pfx: table_prefix}
    )
  end

  def where_expr
    if question1.nil?
      @where_expr ||= raise Report::ReportError, "A zero/non-zero calculation must specify question1."
    end
    Report::Expression.new(sql_tplt: "__TBL_PFX__questions.id = '#{question1.id}'",
                           name: "where", clause: :where, chunks: {tbl_pfx: table_prefix})
  end

  def joins
    %i[options choices option_sets]
  end

  def data_type_expr
    Report::Expression.new(sql_tplt: "'text'", name: "type", clause: :select)
  end

  def output_data_type
    "text"
  end
end
