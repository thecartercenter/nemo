# A calculation that returns 0 if the answer value is 0 and 1 otherwise
class Report::ZeroNonzeroCalculation < Report::Calculation
  def name_expr
    "IF(answers.value > 0, 'Non-Zero', 'Zero')"
  end

  def value_expr
    "IF(answers.value > 0, 1, 0)"
  end
  
  def sort_expr
    "IF(answers.value > 0, 1, 0)"
  end
  
  def where_expr
    raise Report::ReportError.new("A zero/non-zero calculation must specify question1.") if question1.nil?
    "questions.id = #{question1.id}"
  end
end