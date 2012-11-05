class Report::FieldSet
  attr_accessor :fields
  
  def initialize(fields)
    @fields = fields
  end
  
  def headers(results)
    fields.collect{|f| f.headers}.flatten
  end
  
  def multiple?
    fields.size > 1 || fields.first && fields.first.question_type
  end
  
  def kinds
    return @kinds if @kinds
    @kinds = {}
    fields.each do |f|
      if f.attrib then @kinds[:attrib] = true 
      elsif f.question then @kinds[:question] = true
      elsif f.question_type then @kinds[:question_type] = true
      end
    end
    @kinds
  end
  
  def only_field
    fields.size == 1 && fields.first || nil
  end
  
  def title
    if kinds[:attrib] && (kinds[:question] || kinds[:question_type])
      "Attribs, Questions"
    elsif kinds[:attrib]
      "Attribs"
    else
      "Questions"
    end
  end
  
  def key(result_row)
    result_row["Key"]
  end
  
  def apply(rel, aggregation)
    raise ReportError.new("There are no fields defined") if fields.empty?
    
    if aggregation.is_list?
      # for each field, we simply add that field, but with no grouping
      return fields.inject(rel){|rel, f| rel = f.apply(rel)}
      
    # otherwise this is one of the other kinds
    else
      # if there is an attrib field
      if kinds[:attrib]
        # if it's not the only one, or if it's an invalid field, raise an error
        raise Report::ReportError.new("Only one attrib field allowed.") if fields.size > 1
      
        # get ref to the first field
        field = fields.first
      
        # add the select query and the joins
        rel = rel.select(aggregation.encode(field.attrib.to_sql) + " AS `Value`")
        return field.attrib.apply_joins(rel)
      
      # otherwise they're all question or question_type fields
      else
        # get questions and questioning IDs
        questions = fields.collect{|f| f.question || f.question_type.questions}.flatten
        qing_ids = questions.collect{|q| q.qing_ids}.flatten.join(",")
      
        # if the is more than one question, add the question code, join, and group
        if multiple?
          rel = rel.select("CONCAT('answer_q', questions.id) AS `Key`").
            joins("INNER JOIN questionings ON answers.questioning_id = questionings.id " + 
                  "INNER JOIN questions ON questionings.question_id = questions.id").
            group("questions.code")
        end
              
        # add the question code and answer value to select
        expr = aggregation.encode("IFNULL(answers.value, IFNULL(answers.datetime_value, IFNULL(answers.date_value, answers.time_value)))") + " AS `Value`"
        return rel.select(expr).from("answers").
          joins("INNER JOIN responses ON responses.id = answers.response_id AND answers.questioning_id IN (#{qing_ids})")
      end
    end
  end
end