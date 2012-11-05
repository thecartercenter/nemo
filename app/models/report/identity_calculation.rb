# A calculation that just returns the referenced argument with no modification
class Report::IdentityCalculation < Report::Calculation
  def name_expr
    "IFNULL(aotr.str, cotr.str)"
  end

  def value_expr
    "IFNULL(ao.value, co.value)"
  end
  
  def sort_expr
    "IF(option_sets.ordering = 'value_asc', 1, -1) * IFNULL(ao.value, co.value)"
  end
  
  def where_expr
    raise Report::ReportError.new("An identity calculation must specify question1.") if question1.nil?
    "questions.id = #{question1.id}"
  end
end