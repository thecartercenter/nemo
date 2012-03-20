class Report::Field < ActiveRecord::Base
  belongs_to(:report, :class_name => "Report::Report", :foreign_key => :report_report_id)
  belongs_to(:question)
  belongs_to(:question_type)
  
  attr_accessor :subfields
  
  def apply(rel)
    # if report is answer mode, the meaning of fields is different
    if report.mode == :answers
      if question
        rel.where("questions.id = #{question.id}")
      elsif question_type
        rel.where("question_types.id = #{question_type.id}")
      end
    else
      if attrib_name
        rel.select(full_expr)
      elsif question
        return rel if question.questionings.empty?
        qing_ids = question.questionings.collect{|qing| qing.id}.join(",")
        rel.select("#{full_expr} AS '#{question.code}'").
          joins("LEFT OUTER JOIN answers #{ans_tbl} ON responses.id = #{ans_tbl}.response_id").
          where("#{ans_tbl}.questioning_id IN (#{qing_ids})")
      elsif question_type
        return rel if question_type.questions.empty?
        @subfields = []
        question_type.questions.each do |q| 
          @subfields << (f = Report::Field.new(:report => report, :question => q))
          rel = f.apply(rel)
        end
        rel
      # else this is just a response count
      else
        rel.select("COUNT(responses.id) AS count")
      end
    end
  end
  
  def name
    attrib_name || question.code
  end
  
  def expr
    attrib_name || question && "#{ans_tbl}.value"
  end
  
  def idx
    @idx ||= 1000 + rand(8999)
  end

  def ans_tbl
    @ans_tbl ||= "a#{idx}"
  end
  
  private
    
    # gets the full select expression by applying the reports calculation and aggregation
    def full_expr
      return @full_expr if @full_expr

      # start with the basic
      @full_expr = expr

      # apply the calculation
      @full_expr = report.calculation.apply(self, @full_expr) if report.calculation

      # apply the aggregation
      @full_expr = report.aggregation.apply(self, @full_expr) if report.aggregation

      # return
      @full_expr
    end
end
