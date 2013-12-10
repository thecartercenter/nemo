# A calculation that just returns the referenced argument with no modification
class Report::IdentityCalculation < Report::Calculation
  def name_expr
    arg1.name_expr(:tbl_pfx => table_prefix)
  end

  def value_expr
    arg1.value_expr(:tbl_pfx => table_prefix)
  end

  def sort_expr
    arg1.sort_expr(:tbl_pfx => table_prefix)
  end

  def where_expr
    raise Report::ReportError.new("identity calc must specify question1 or attrib1") if arg1.nil?
    arg1.where_expr(:tbl_pfx => table_prefix)
  end

  def data_type_expr
    Report::Expression.new(:sql_tplt => "'#{arg1.data_type}'", :name => "type", :clause => :select)
  end

  def output_data_type
    arg1.data_type
  end

  def joins
    arg1.joins
  end
end
