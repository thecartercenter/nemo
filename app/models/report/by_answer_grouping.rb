class Report::ByAnswerGrouping < Report::Grouping
  belongs_to(:question)
  
  def self.select_options
    Question.includes(:type).where(:"question_types.name" => "select_one").all.collect{|q| [human_name(q), "by_answer_#{q.id}"]}
  end
  
  def self.select_group_name; "Questions"; end
  
  def self.human_name(question)
    "#{question.code}"
  end
  
  def apply(rel)
    case question.type.name
    when "select_one"
      # get questioning ids
      qing_ids = question.questionings.collect{|qing| qing.id}.join(",")
      raise Report::ReportError.new("The question #{question.code} doesn't appear on any forms.") if qing_ids.empty?
      
      # do it!
      expr = "aotr#{uid}.str"
      rel.select("#{expr} as `#{col_name}`, ao#{uid}.value as `#{value_col_name}`").
        joins("LEFT JOIN answers a#{uid} ON responses.id = a#{uid}.response_id").
        joins("LEFT JOIN options ao#{uid} ON a#{uid}.option_id = ao#{uid}.id").
        joins("LEFT JOIN translations aotr#{uid} ON " +
          "(aotr#{uid}.obj_id = ao#{uid}.id and aotr#{uid}.fld = 'name' and aotr#{uid}.class_name = 'Option' " +
            "AND aotr#{uid}.language_id = (SELECT id FROM languages WHERE code = 'eng'))").
        where("a#{uid}.questioning_id IN (#{qing_ids})").
        group(expr)
    end
  end
  
  def col_name
    "answer_#{question.code.gsub(' ', '_').downcase}"
  end
  
  def form_choice
    "by_answer_#{question_id}"
  end
  
  def assoc_id=(id)
    self.question_id = id
  end
  
  def to_s
    self.class.human_name(question)
  end
  
  def process_results(results)
    results
  end
  
  private
    def uid
      @uid ||= 1000 + rand(8999)
    end
end