# Represents a set of answers to one Questioning.
# Usually has only one answer, except in case of Question with multi-level OptionSet.
# See AnswerArranger for more documentation.
class AnswerSet
  attr_accessor :questioning, :answers

  delegate :qtype, :required?, :question, :condition,
    :full_dotted_rank, :display_conditionally?, to: :questioning
  delegate :name, :hint, to: :question, prefix: true
  delegate :option_set, to: :question
  delegate :levels, to: :option_set
  delegate :first, to: :answers
  delegate :errors, :choices, :all_choices, :value, :datetime_value, :date_value, :time_value, :response_id, :questioning_id, :relevant, :inst_num, to: :first

  # Builds Answer attribute hashes from submitted answer_set params.
  # Returns an array of Answer attribute hashes.
  def self.answers_attributes_for(params)
    attribs = params.values.map do |as|
      if as[:answers]
        as.delete(:answers).values.map.with_index{ |a, i| a.merge(as).merge(rank: i + 1) }.tap do |attribs|
          # Remove nil answers from set unless there is only one.
          attribs.reject!{ |a| a[:option_id].nil? } unless attribs.size == 1
        end
      else
        as
      end
    end.flatten
  end

  def initialize(attribs = {})
    attribs.each{ |k,v| instance_variable_set("@#{k}", v) }
    ensure_answers
  end

  def multilevel?
    option_set.nil? ? false : option_set.multilevel?
  end

  # True if all answers are blank.
  def blank?
    answers.all?(&:blank?)
  end

  def option_node_ids
    answers.map(&:option_node_id)
  end

  def option_node_path
    OptionNodePath.new(option_set: option_set, target_node: lowest_non_nil_answer.try(:option_node))
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

  # Returns the non-nil answer with the lowest rank. May return nil if the set is blank.
  def lowest_non_nil_answer
    answers.reverse.find(&:present?)
  end
end
