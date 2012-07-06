class Report::QuestionWrapper
  attr_reader :question
  
  def initialize(question)
    @question = question
  end
  
  def apply(rel, options = {})
    # get questioning ids
    qing_ids = @question.questionings.collect{|qing| qing.id}.join(",")
    raise Report::ReportError.new("The question #{@question.code} doesn't appear on any forms.") if qing_ids.empty?

    case @question.type.name
    when "select_one", "select_multiple"
      expr = "aotr#{sfx}.str"

      # add the select and answers join
      rel = rel.select("#{expr} as `#{sql_col_name}`, ao#{sfx}.value as `#{sql_col_name}_value`").
        joins("LEFT JOIN answers a#{sfx} ON responses.id = a#{sfx}.response_id AND a#{sfx}.questioning_id IN (#{qing_ids})")
      
      # add the options join
      if @question.type.name == "select_one"
        rel = rel.joins("LEFT JOIN options ao#{sfx} ON a#{sfx}.option_id = ao#{sfx}.id")
      else
        rel = rel.joins("INNER JOIN choices ac#{sfx} ON a#{sfx}.id = ac#{sfx}.answer_id").
          joins("INNER JOIN options ao#{sfx} ON ac#{sfx}.option_id = ao#{sfx}.id")
      end
      
      # add the translations join
      rel = rel.joins("LEFT JOIN translations aotr#{sfx} ON " +
          "(aotr#{sfx}.obj_id = ao#{sfx}.id and aotr#{sfx}.fld = 'name' and aotr#{sfx}.class_name = 'Option' " +
            "AND aotr#{sfx}.language_id = (SELECT id FROM languages WHERE code = 'eng'))")        
      
      # add the group by if necessary
      rel = rel.group(expr) if options[:group]
    else
      rel = rel.select("IFNULL(a#{sfx}.value, IFNULL(a#{sfx}.datetime_value, IFNULL(a#{sfx}.date_value, a#{sfx}.time_value))) AS `#{sql_col_name}`").
        joins("LEFT JOIN answers a#{sfx} ON responses.id = a#{sfx}.response_id AND a#{sfx}.questioning_id IN (#{qing_ids})")
    end
    rel
  end
  
  def sql_col_name
    "answer#{sfx}"
  end
  
  def header
    {:name => @question.code, :value => @question.code, :key => sql_col_name, :fieldlet => self}
  end
  
  def has_timezone?
    question.type.has_timezone?
  end
  
  def temporal?
    question.type.temporal?
  end
  
  def data_type
    question.type.name
  end
  
  private
    def sfx
      "_q#{@question.id}"
    end
end