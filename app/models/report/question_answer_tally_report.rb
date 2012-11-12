class Report::QuestionAnswerTallyReport < Report::TallyReport
  belongs_to(:option_set)
  has_many(:calculations, :class_name => "Report::Calculation", :foreign_key => "report_report_id", :dependent => :destroy, :autosave => true)

  accepts_nested_attributes_for(:calculations, :allow_destroy => true)

  def as_json(options = {})
    h = super(options)
    h[:calculations] = calculations
    h
  end

  protected
  
    def prep_relation(rel)
      joins = []
      
      # add tally to select
      rel = rel.select("COUNT(responses.id) AS tally")
    
      # add question grouping
      expr = question_labels == "Titles" ? "question_trans.str" : "questions.code"
      rel = rel.select("#{expr} AS pri_name, #{expr} AS pri_value, 'text' AS pri_type")
      joins << :questions
      joins << :question_trans if question_labels == "Titles"
      rel = rel.group(expr)
    
      # add answer grouping
      # if we have an option set, we don't use calculation objects
      if option_set
        expr = "IFNULL(aotr.str, cotr.str)"
        rel = rel.select("#{expr} AS sec_name")
        rel = rel.group(expr)
        expr = "IFNULL(ao.value, co.value)"
        rel = rel.select("#{expr} AS sec_value")
        rel = rel.group(expr)
        rel = rel.where("option_sets.id" => option_set.id)
        
        # type is just text
        rel = rel.select("'text' AS sec_type")
        
        # default sort by option value and then by question
        opt_value_sort_order = option_set.ordering == "value_asc" ? "" : "DESC"
        rel = rel.order("sec_value #{opt_value_sort_order}, pri_value")

      # we don't have an option set, so expect calculation objects
      else
        raise Report::ReportError.new("Report has no calculations") if calculations.empty?
        
        # get expression fragments
        # this could be optimized by grouping name/value/sort for each calculation type, but i don't think it will impact performance much
        name_exprs = calculations.collect{|c| c.name_expr}
        value_exprs = calculations.collect{|c| c.value_expr}
        sort_exprs = calculations.collect{|c| c.sort_expr}
        where_exprs = calculations.collect{|c| c.where_expr}
        
        # build full expressions
        name_expr = build_nested_if(name_exprs, where_exprs)
        value_expr = build_nested_if(value_exprs, where_exprs)
        sort_expr = build_nested_if(sort_exprs, where_exprs)
        
        # add the selects and groups
        rel = rel.select("#{name_expr} AS sec_name, #{value_expr} AS sec_value, #{sort_expr} AS sec_sort_value, 'text' AS sec_type")
        rel = rel.group(name_expr).group(value_expr).group(sort_expr)
        
        # add the unified wheres
        rel = rel.where("(" + where_exprs.join(" OR ") + ")")
        
        # sort by sort expression
        rel = rel.order("option_sets.name, sec_sort_value, pri_value")
      end

      # add joins to relation
      joins << :options << :choices << :option_sets
      rel = add_joins_to_relation(rel, joins)
      
      # apply filter
      rel = filter.apply(rel) unless filter.nil?
      
      return rel
    end
    
    def header_title(which)
      which == :row ? "Questions" : "Answers"
    end
    
  private
    # builds a nested SQL IF statement of the form IF(a, x, IF(b, y, IF(c, z, ...)))
    def build_nested_if(exprs, conds)
      if exprs.size == 1
        return exprs.first 
      else
        rest = build_nested_if(exprs[1..-1], conds[1..-1])
        "IF(#{conds.first}, #{exprs.first}, #{rest})"
      end
    end
end
