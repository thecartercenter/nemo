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
    when "select_one"
      # do it!
      expr = "aotr#{sfx}.str"
      rel = rel.select("#{expr} as `#{sql_col_name}`, ao#{sfx}.value as `#{sql_col_name}_value`").
        joins("LEFT JOIN answers a#{sfx} ON responses.id = a#{sfx}.response_id AND a#{sfx}.questioning_id IN (#{qing_ids})").
        joins("LEFT JOIN options ao#{sfx} ON a#{sfx}.option_id = ao#{sfx}.id").
        joins("LEFT JOIN translations aotr#{sfx} ON " +
          "(aotr#{sfx}.obj_id = ao#{sfx}.id and aotr#{sfx}.fld = 'name' and aotr#{sfx}.class_name = 'Option' " +
            "AND aotr#{sfx}.language_id = (SELECT id FROM languages WHERE code = 'eng'))")        
      rel = rel.group(expr) if options[:group]
    else
      rel = rel.select("a#{sfx}.value AS `#{sql_col_name}`").
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
  
  private
    def sfx
      "_q#{@question.id}"
    end
end