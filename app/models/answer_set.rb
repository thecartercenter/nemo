# Represents a set of answers to one Questioning.
# Usually has only one answer, except in case of Question with multi-level OptionSet.
class AnswerSet
  attr_accessor :questioning, :answers

  delegate :qtype, :required?, :question, :condition, :to => :questioning
  delegate :name, :hint, :option_set, :to => :question, :prefix => true
  delegate :first, :to => :answers
  delegate :errors, :choices, :all_choices, :value, :datetime_value, :date_value, :time_value, :response_id, :questioning_id, :relevant, :to => :first
  delegate :levels, :to => :option_set

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
      [Answer.new(questioning: questioning)]
    end
  end
end