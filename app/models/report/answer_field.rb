class Report::AnswerField < Report::Field
  
  attr_reader :question
  
  def initialize(question)
    @question = question
  end
    
  def name_expr(table_prefix)
    case question.type.name
    when "select_one"
      "#{table_prefix}aotr.str"
    when "select_multiple"
      "#{table_prefix}cotr.str"
    else
      value_expr(table_prefix)
    end
  end

  def value_expr(table_prefix)
    case question.type.name
    when "select_one"
      "#{table_prefix}ao.value"
    when "select_multiple"
      "#{table_prefix}co.value"
    when "integer"
      "CONVERT(#{table_prefix}answers.value, SIGNED INTEGER)"
    when "decimal"
      "CONVERT(#{table_prefix}answers.value, DECIMAL)"
    when "datetime"
      "#{table_prefix}answers.datetime_value"
    when "date"
      "#{table_prefix}answers.date_value"
    when "time"
      "#{table_prefix}answers.time_value"
    else
      "#{table_prefix}answers.value"
    end
  end
  
  def where_expr(table_prefix)
    "#{table_prefix}questions.id = #{@question.id}"
  end
  
  def sort_expr(table_prefix)
    case question.type.name
    when "select_one"
      "IF(#{table_prefix}option_sets.ordering = 'value_asc', 1, -1) * #{table_prefix}ao.value"
    when "select_multiple"
      "IF(#{table_prefix}option_sets.ordering = 'value_asc', 1, -1) * #{table_prefix}co.value"
    else
      value_expr(table_prefix)
    end
  end
  
  def data_type
    question.type.name
  end
  
  def joins
    case question.type.name
    when "select_one", "select_multiple"
      [:options, :choices, :option_sets]
    else
      [:questions]
    end
  end
end