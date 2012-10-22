class Report::QuestionAnswerTallyReport < Report::TallyReport
  belongs_to(:option_set)
  has_many(:calculations, :class_name => "Report::Calculation", :dependent => :destroy, :autosave => true)

  protected
  
    def prep_relation(rel)
      joins = []
      
      # add tally to select
      rel = rel.select("COUNT(responses.id) AS tally")
    
      # add question grouping
      expr = "questions.code"
      rel = rel.select("#{expr} AS question")
      joins << :questions
      rel = rel.group(expr)
    
      # add answer grouping
      # if we have an option set, we don't use calculation objects
      if option_set
        expr = "IFNULL(aotr.str, cotr.str)"
        rel = rel.select("#{expr} AS answer_name")
        rel = rel.group(expr)
        expr = "IFNULL(ao.value, co.value)"
        rel = rel.select("#{expr} AS answer_value")
        rel = rel.group(expr)
        rel = rel.where("option_sets.id" => option_set.id)
        joins << :options << :choices << :option_sets
        
        # default sort by option value and then by question
        opt_value_sort_order = option_set.ordering == "value_asc" ? "" : "DESC"
        rel = rel.order("answer_value #{opt_value_sort_order}, question")
      end
      
      # add joins to relation
      rel = add_joins_to_relation(rel, joins)
        
      #selects = calculations.collect{|c| c.select}
      #conditions = calculations.collect{|c| c.condition}
      return rel
    end
end
