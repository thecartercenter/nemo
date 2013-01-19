class Report::AnswerField < Report::Field
  
  attr_reader :question
 
  @@expression_params = [
    {:sql_tplt => "__TBL_PFX__aotr.str", :name => "select_one_name", :clause => :select, :join => :options},
    {:sql_tplt => "__TBL_PFX__cotr.str", :name => "select_multiple_name", :clause => :select, :join => :choices},
    {:sql_tplt => "__TBL_PFX__ao.value", :name => "select_one_value", :clause => :select, :join => :options},
    {:sql_tplt => "__TBL_PFX__co.value", :name => "select_multiple_value", :clause => :select, :join => :choices},
    {:sql_tplt => "CONVERT(__TBL_PFX__answers.value, SIGNED INTEGER)", :name => "integer_value", :clause => :select, :join => :answers},
    {:sql_tplt => "CONVERT(__TBL_PFX__answers.value, DECIMAL)", :name => "decimal_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.datetime_value", :name => "datetime_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.date_value", :name => "date_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.time_value", :name => "time_value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__answers.value", :name => "value", :clause => :select, :join => :answers},
    {:sql_tplt => "__TBL_PFX__questions.id = __QUESTION_ID__", :name => "where_expr", :clause => :where, :join => :questions},
    {:sql_tplt => "IF(__TBL_PFX__option_sets.ordering = 'value_asc', 1, -1) * __TBL_PFX__ao.value", :name => "select_one_sort", :clause => :select, :join => :options},
    {:sql_tplt => "IF(__TBL_PFX__option_sets.ordering = 'value_asc', 1, -1) * __TBL_PFX__co.value", :name => "select_multiple_sort", :clause => :select, :join => :choices}
  ]

  def self.expression(options)
    Report::Expression.new(expression_params_by_name[options[:name]].merge(:chunks => options[:chunks]))
  end
  
  def self.expression_params_by_name
    @@expression_params_by_name ||= @@expression_params.index_by{|ep| ep[:name]}
  end
  
  def self.expression_params_by_clause
    @@expression_params_by_clause ||= @@expression_params.group_by{|ep| ep[:clause]}
  end
  
  def self.expressions_for_clause(clause, joins, chunks = {})
    expression_params_by_clause[clause].collect{|ep| Report::Expression.new(ep.merge(:chunks => chunks)) if joins.include?(ep[:join])}.compact
  end
   
  def initialize(question)
    @question = question
  end
    
  def name_expr(chunks)
    @name_expr ||= case data_type
    when "select_one", "select_multiple"
      self.class.expression(:name => "#{data_type}_name", :chunks => chunks)
    else
      value_expr(chunks)
    end
  end

  def value_expr(chunks)
    @value_expr ||= case data_type
    when "select_one", "select_multiple", "integer", "decimal", "datetime", "date", "time"
      self.class.expression(:name => "#{data_type}_value", :chunks => chunks)
    else
      self.class.expression(:name => "value", :chunks => chunks)
    end
  end
  
  def where_expr(chunks)
    @where_expr ||= self.class.expression(:name => "where_expr", :chunks => chunks.merge(:question_id => @question.id))
    @where_expr
  end
  
  def sort_expr(chunks)
    case data_type
    when "select_one", "select_multiple"
      self.class.expression(:name => "#{data_type}_sort", :chunks => chunks)
    else
      value_expr(chunks)
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