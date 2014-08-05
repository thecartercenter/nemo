# Represents a set of answers to one Questioning.
# Usually has only one answer, except in case of Question with multi-level OptionSet.
class AnswerSet
  attr_accessor :questioning, :answers

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    # Need to build empty answers for questioning if not given.
    build_answers if answers.nil?
  end

  private

  def build_answers
    self.answers = if questioning.multi_level?
      questioning.level_count.times.map{ |i| Answer.new(questioning: questioning, rank: i + 1) }
    else
      [Answer.new(questioning: questioning, rank: i + 1)]
    end
  end
end