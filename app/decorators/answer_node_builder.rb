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
    options[:dont_load_answers] = false unless options.has_key?(:dont_load_answers)
  end

  # Returns an array of AnswerNodes.
  def build
    load_answers
    scan_instance_counts
    root_node = build_node(response.form.root_group, 1)
    root_node.instances.first.nodes
  end

  private

  attr_accessor :response, :answers, :instance_counts, :options

  # We do our own loading here to control order, eager loading, etc.
  # (Unless instructed not to).
  def load_answers
    if options[:dont_load_answers]
      self.answers = response.answers
    else
      # We eager load options, choices, and questionings since they are bound to be used.
      # We order the answers so that the answers in answer sets will be in the proper rank order.
      self.answers = response.answers.
        includes(:questioning, :option, choices: :option).
        order(:questioning_id, :inst_num, :rank)
    end
  end

  # Returns a new AnswerNode for the given FormItem and instance number.
  # Returns nil if:
  # - FormItem is a hidden Questioning and there are no answers for it.
  # - include_blank_answers is false and there are no matching answers.
  def build_node(item, inst_num)
    if item.is_a?(QingGroup)
      build_node_for_group(item, inst_num)
    else
      build_node_for_questioning(item, inst_num)
    end
  end

  def build_node_for_group(item, inst_num)
    AnswerNode.new(item: item).tap do |node|
      instance_count = instance_counts[item.id] || 0

      # Don't return a node if there are no answers for a group and blank_answers isn't on.
      if instance_count == 0 && !options[:include_blank_answers]
        return nil
      else
        # If there are no instances and we've gotten this far, we still want to include one.
        instance_count = 1 if instance_count == 0

        # Build instances.
        for inst_num in 1..instance_count
          node.instances << AnswerInstance.new(
            num: inst_num,
            nodes: item.children.map{ |c| build_node(c, inst_num) }.compact
          )
        end
      end

      # Add blank instance if requested and this is a repeat group.
      if item.repeats? && options[:include_blank_answers]
        node.blank_instance = AnswerInstance.new(
          nodes: item.children.map{ |c| build_node(c, :blank) }.compact,
          blank: true
        )
      end
    end
  end

  def build_node_for_questioning(item, inst_num)
    AnswerNode.new(item: item).tap do |node|
      answers = answers_for(item.id, inst_num)
      if answers.none? && (item.hidden? || !options[:include_blank_answers])
        return nil
      else
        node.set = AnswerSet.new(questioning: item, answers: answers)
      end
    end
  end

  # Gets the max inst_num values for all QingGroups on this Response.
  # If a QingGroup has no answers at all, instance_counts[group_id] will be nil.
  def scan_instance_counts
    self.instance_counts = {}

    answers.each do |answer|
      parent_id = answer.questioning.parent_id
      current_max = instance_counts[parent_id]
      if current_max.nil? || answer.inst_num > current_max
        instance_counts[parent_id] = answer.inst_num
      end
    end
  end

  def answers_for(qing_id, inst_num)
    return [] if inst_num == :blank
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
