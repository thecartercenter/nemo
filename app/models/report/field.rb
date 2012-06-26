class Report::Field < ActiveRecord::Base
  belongs_to(:report, :class_name => "Report::Report", :foreign_key => :report_report_id)
  belongs_to(:attrib, :class_name => "Report::ResponseAttribute")
  belongs_to(:question)
  belongs_to(:question_type)
  
  def self.select_options
    [
      ["Attributes", Report::ResponseAttribute.all.collect{|ra| [ra.name, "attrib_#{ra.id}"]}],
      ["Question Types", QuestionType.all.collect{|qt| [qt.long_name, "qtype_#{qt.id}"]}],
      ["Questions", Question.all.collect{|q| [q.code, "question_#{q.id}"]}]
    ]
  end
  
  def self.choices
    [
      {:name => "Attributes", :choices => Report::ResponseAttribute.all.collect{|ra| 
        {:name => ra.name, :full_id => "attrib_#{ra.id}", :data_type => ra.data_type}}},
      {:name => "Question Types", :choices => QuestionType.all.collect{|qt| 
        {:name => qt.long_name, :full_id => "qtype_#{qt.id}", :data_type => qt.name}}},
      {:name => "Questions", :choices => Question.includes(:type).all.collect{|q| 
        {:name => q.code, :full_id => "question_#{q.id}", :data_type => q.type.name}}}
    ]
  end
  
  # the header labels for this field
  def headers
    fieldlets.collect{|fl| fl.header}
  end
  
  # apply this field to the relation with no grouping
  def apply(rel)
    raise Report::ReportError.new("You must choose at least one Attribute or Question.") if fieldlets.empty?
    fieldlets.inject(rel){|rel, fl| rel = fl.apply(rel, :group => false)}
  end
  
  # returns a string identifying this field including whether its an attrib, question, or question_type
  def full_id
    if attrib then "attrib_#{attrib.id}"
    elsif question then "question_#{question.id}"
    elsif question_type then "qtype_#{question_type.id}"
    end
  end
  
  # sets up this field based on the given full_id
  def full_id=(fi)
    return if fi.nil?
    raise "Invalid field full_id" unless fi.match(/^([a-z]+)_(\d+)/)
    pfx = $1
    sub_id = $2
    self.attrib = self.question = self.question_type = nil
    case pfx
    when "attrib" then self.attrib = Report::ResponseAttribute.find(sub_id)
    when "question" then self.question = Question.find(sub_id)
    when "qtype" then self.question_type = QuestionType.find(sub_id)
    end
  end
    
  
  # a fieldlet is an object that represents an attrib or an individual question
  # ResponseAttributes and QuestionWrappers are fieldlets
  def fieldlets
    @fieldlets ||= if attrib
      [attrib]
    elsif question
      [Report::QuestionWrapper.new(question)] 
    elsif question_type
      question_type.questions.collect{|q| Report::QuestionWrapper.new(q) unless q.forms.empty?}.compact
    else
      []
    end
  end
end
