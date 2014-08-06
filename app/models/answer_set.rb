# Represents a set of answers to one Questioning.
# Usually has only one answer, except in case of Question with multi-level OptionSet.
class AnswerSet
  attr_accessor :questioning, :answers

  delegate :qtype, :required?, :question, :condition, to: :questioning
    delegate :name, :hint, to: :question, prefix: true
    delegate :option_set, to: :question
      delegate :levels, :multi_level?, to: :option_set
  delegate :first, to: :answers
    delegate :errors, :choices, :all_choices, :value, :datetime_value, :date_value, :time_value, :response_id, :questioning_id, :relevant, to: :first

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    # Need to build empty answers for questioning if not given.
    build_answers if answers.nil?
  end

  # Returns the available Options for the given answer.
  # If the answer's rank is > 1 and the answer before it is currently nil, returns [].
  def options_for(answer)
    path = answers_before(answer).map(&:option)
    option_set.options_at_end_of_path(path) || []
  end

  # Returns an array of all answers in this set before the given answer, by rank.
  # Returns [] if the given answer is first in the set.
  # Returns nil if not found.
  def answers_before(answer)
    return nil unless pos = answers.index(answer)
    answers[0...pos]
  end

  private

  def build_answers
    self.answers = if questioning.multi_level?
      questioning.level_count.times.map{ |i| Answer.new(questioning: questioning, rank: i + 1) }
    else
      [Answer.new(questioning: questioning)]
    end
  end
end