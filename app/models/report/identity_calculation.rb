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

# A calculation that just returns the referenced argument with no modification
class Report::IdentityCalculation < Report::Calculation
  def name_expr(prefer_value = false)
    arg1.name_expr({tbl_pfx: table_prefix}, prefer_value)
  end

  def value_expr
    arg1.value_expr(tbl_pfx: table_prefix)
  end

  def sort_expr
    arg1.sort_expr(tbl_pfx: table_prefix)
  end

  def where_expr
    raise Report::ReportError, "identity calc must specify question1 or attrib1" if arg1.nil?
    arg1.where_expr(tbl_pfx: table_prefix)
  end

  def data_type_expr
    Report::Expression.new(sql_tplt: "'#{arg1.data_type}'", name: "type", clause: :select)
  end

  def output_data_type
    arg1.data_type
  end

  delegate :joins, to: :arg1
end
