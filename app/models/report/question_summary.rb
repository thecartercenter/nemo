# models a summary of the answers for a question on a form
class Report::QuestionSummary
  attr_reader :questioning

  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def qtype
    questioning.qtype
  end
end