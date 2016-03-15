# Creates AnswerNodes, AnswerInstances, and AnswerSets for a given response.
# None of these are persisted to the database. Only Answer is persisted.
#
# Answer object hierarchy:
#
# AnswerNode
# - All answer data for a given FormItem within a specific AnswerInstance
# - Has many AnswerInstances (if item is QingGroup) or one AnswerSet (if item is Qing)
# AnswerInstance
# - A set of AnswerNodes corresponding to one repeat instance of a QingGroup
# - Has many AnswerNodes (at least one)
# - Only repeat groups can have more than one AnswerInstance in their AnswerNode.
# AnswerSet
# - Set of one or more answers for a given question and instance
# Answer
# - A single answer

class AnswerNodeBuilder
  def initialize(response, options = {})
    self.response = response
    self.options = options
    options[:include_blank_answers] = false unless options.has_key?(:include_blank_answers)
  end

  # Returns an array of AnswerNodes.
  def build
    load_answers
    scan_max_instance_nums
    root_node = build_node(response.form.root_group, 1)
    root_node.instances.first.nodes
  end

  private

  attr_accessor :response, :answers, :max_inst_nums, :options

  # We do our own loading here to control order, eager loading, etc.
  def load_answers
    # We eager load options, choices, and questionings since they are bound to be used.
    # We order the answers so that the answers in answer sets will be in the proper rank order.
    # questioning_id and inst_num are included to match the DB index.
    self.answers = response.answers.
      includes(:questioning, :option, choices: :option).
      order(:questioning_id, :inst_num, :rank)
  end

  # Returns a new AnswerNode for the given FormItem and instance number.
  # Returns nil if:
  # - FormItem is a hidden Questioning and there are no answers for it.
  # - include_blank_answers is false and there are no matching answers.
  def build_node(item, inst_num)
    node = AnswerNode.new(item: item)
    if item.is_a?(QingGroup)
      for inst_num in 1..(max_inst_nums[item.id] || 1)
        ai = AnswerInstance.new(nodes: item.children.map{ |c| build_node(c, inst_num) }.compact)
        node.instances << ai
      end
    else
      answers = answers_for(item.id, inst_num)
      if answers.none? && (item.hidden? || !options[:include_blank_answers])
        return nil
      else
        node.set = AnswerSet.new(questioning: item, answers: answers)
      end
    end
    node
  end

  # Gets the max answer inst_num numbers for all QingGroups on this Response.
  def scan_max_instance_nums
    self.max_inst_nums = {}

    answers.each do |answer|
      parent_id = answer.questioning.parent_id
      max_inst_nums[parent_id] = [max_inst_nums[parent_id], answer.inst_num, 1].compact.max
    end
  end

  def answers_for(qing_id, inst_num)
    return [] unless answer_table[qing_id]
    answer_table[qing_id][inst_num]
  end

  def answer_table
    return @answer_table if @answer_table
    @answer_table = {}
    by_qing_id = answers.group_by(&:questioning_id)
    by_qing_id.each do |qing_id, answers_for_qing|
      @answer_table[qing_id] = answers_for_qing.group_by(&:inst_num)
    end
    @answer_table
  end
end
