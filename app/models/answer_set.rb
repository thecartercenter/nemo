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

  # Builds Answer attribute hashes from submitted answer_set params.
  # Returns an array of Answer attribute hashes.
  def self.answers_attributes_for(params)
    params.values.map do |as|
      if as[:answers]
        as.delete(:answers).values.map.with_index{ |a, i| a.merge(as).merge(rank: i + 1) }
      else
        as
      end
    end.flatten
  end

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    ensure_answers
  end

  # Returns the available Options for the given answer.
  # If the answer's rank is > 1 and the answer before it is currently nil, returns [].
  def options_for(answer)
    path = answers_before(answer).map(&:option_id)
    option_set.options_for_node(path) || []
  end

  # Returns an array of all answers in this set before the given answer, by rank.
  # Returns [] if the given answer is first in the set.
  # Returns nil if not found.
  def answers_before(answer)
    return nil unless pos = answers.index(answer)
    answers[0...pos]
  end

  private

  # Ensures empty answers for all levels of questioning.
  def ensure_answers
    self.answers ||= []
    (questioning.level_count || 1).times.each do |i|
      rank = (questioning.level_count || 1) > 1 ? i + 1 : nil
      answers[i] ||= Answer.new(questioning: questioning, rank: rank)
    end
  end
end