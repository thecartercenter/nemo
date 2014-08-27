# For a select question with a multi_level option set, represents one level of the question.
# For all other questions, just an alias.
class Subquestion
  attr_accessor :question, :level, :rank

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def odk_code
    multi_level? ? "#{question.odk_code}_#{rank}" : question.odk_code
  end

  def name(*args)
    base = question.send(:name, *args)
    multi_level? ? "#{base} - #{level.name}" : base
  end

  def method_missing(*args)
    question.send(*args)
  end
end