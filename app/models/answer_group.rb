class AnswerGroup
  attr_accessor :response

  def initialize(response)
    @response = response
    @answers = response.answers
    create_groups
  end

  def create_groups
    @group_hash = {}

    @answers.each do |answer|
      questioning = answer.questioning
      group = questioning.parent
      group_id = group.id

      if group.repeats
        group_number = answer.group_number
        @group_hash[group_id] ||= {}
        @group_hash[group_id][group_number] ||= {}
        @group_hash[group_id][group_number][questioning] = answer_set_for_questioning(questioning, group_number)
      else
        @group_hash[group.id] = answer_set_for_questioning(questioning)
      end
    end

    @group_hash
  end

  def for_group(group)
    @group_hash[group.id]
  end


  def answer_set_for_questioning(questioning, group_number = nil)
    # Build a hash of answer sets on the first call.
    answer_sets_by_questioning ||= {}.tap do |hash|
      @answers.group_by(&:questioning).each do |qing, answers|
        answers = answers.select{|a| a.group_number == group_number } if group_number.present?
        hash[qing] = AnswerSet.new(questioning: qing, answers: answers)
      end
    end

    # If answer set already exists, it will be in the answer_sets_by_questioning hash, else create a new one.
    unless answer_sets_by_questioning[questioning]
      answer_sets_by_questioning[questioning] = AnswerSet.new(questioning: questioning)
    end

    answer_sets_by_questioning[questioning]
  end
end
