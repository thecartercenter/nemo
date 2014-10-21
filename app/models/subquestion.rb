# For a select question with a multi_level option set, represents one level of the question.
# For all other questions, just an alias.
class Subquestion
  attr_accessor :question, :level, :rank

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  # Returns the odk code for the question. If options[:previous] is true,
  # returns the code for the immediately previous subquestion (multilevel only).
  def odk_code(options = {})
    if multi_level?
      r = options[:previous] ? rank - 1 : rank
      "#{question.odk_code}_#{r}"
    else
      question.odk_code
    end
  end

  def name(*args)
    base = question.send(:name, *args)
    multi_level? ? "#{base} - #{level.name}" : base
  end

  # Whether this Subquestion is the first in its set (i.e. rank is nil or 1)
  def first_rank?
    rank.nil? || rank == 1
  end

  def method_missing(*args)
    question.send(*args)
  end
end