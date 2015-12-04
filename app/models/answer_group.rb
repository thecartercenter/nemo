class AnswerGroup
  attr_accessor :response

  def initialize(response, empty_answers: false)
    @response = response
    @answers = response.answers.order(:group_number)
    @empty_answers = empty_answers
    create_groups
  end

  def create_groups
    @group_hash = {}
    if @answers.present? && !@empty_answers
      @answers.each do |answer|
        questioning = answer.questioning
        group = questioning.parent
        group_id = group.id
        group_number = answer.group_number || 0
        @group_hash[group_id] ||= {}
        @group_hash[group_id][group_number] ||= {}
        @group_hash[group_id][group_number][questioning] = answer_set_for_questioning(questioning, group_number)
      end
    else
      form = @response.form
      form.arrange_descendants.each do |item, subtree|
        next unless item.is_a? QingGroup
        group = item
        subtree.each do |questioning, subtree|
          @group_hash[group.id] ||= {}
          @group_hash[group.id][0] ||= {}
          @group_hash[group.id][0][questioning] = answer_set_for_questioning(questioning)
        end
      end
    end
    @group_hash
  end

  def for_group(group)
    Rails.logger.ap @group_hash[group.id]
    @group_hash[group.id]
  end


  def answer_set_for_questioning(questioning, group_number = nil)
    # Build a hash of answer sets on the first call.
    answer_sets_by_questioning ||= {}.tap do |hash|
      @answers.group_by(&:questioning).each do |qing, answers|
        answers = answers.select{ |a| a.group_number == group_number } if group_number.present? && group_number > 0
        hash[qing] = AnswerSet.new(questioning: qing, answers: answers)
      end
    end

    # If answer set already exists, it will be in the answer_sets_by_questioning hash, else create a new one.
    if !answer_sets_by_questioning[questioning] || @empty_answers
      answer_sets_by_questioning[questioning] = AnswerSet.new(questioning: questioning)
    end

    answer_sets_by_questioning[questioning]
  end
end
