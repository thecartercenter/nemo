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
    @where_expr ||= raise Report::ReportError.new("A zero/non-zero calculation must specify question1.") if question1.nil?
    Report::Expression.new(:sql_tplt => "__TBL_PFX__questions.id = '#{question1.id}'",
      :name => "where", :clause => :where, :chunks => {:tbl_pfx => table_prefix})
  end

  def joins
    [:options, :choices, :option_sets]
  end

  def data_type_expr
    Report::Expression.new(:sql_tplt => "'text'", :name => "type", :clause => :select)
  end

  def output_data_type
    "text"
  end
end
