class Sms::AnswerHierarchy
  def initialize
    # mapping from qing group ID -> answer group
    @answer_groups = {}
  end

  def lookup(qing_group)
    answer_groups[qing_group.id]
  end

  def answer_group_for(qing)
    qing_group = qing.parent
    answer_group = lookup(qing_group) || build_answer_group(qing_group)

    if qing.multilevel?
      answer_set = AnswerSet.new(form_item: qing)
      answer_group.children << answer_set
      answer_set.new_rank = answer_group.children.length
      answer_group = answer_set
    end

    answer_group
  end

  def add_answer(answer_group, answer)
    answer_group.children << answer
    answer.new_rank = answer_group.children.length
    answer
  end

  def save(response)
    root_node = lookup(response.form.root_group)
    root_node.associate_response(response)

    response.root_node = root_node

    # TODO: We can remove the `validate: false` once various validations are
    # removed from the response model
    response.save!(validate: false)
  end

  private

  def answer_groups
    @answer_groups
  end

  def build_answer_group(qing_group)
    answer_group = AnswerGroup.new(form_item: qing_group)
    link(answer_group)
    answer_groups[qing_group.id] = answer_group
    answer_group
  end

  def link(answer_group)
    qing_group = answer_group.form_item

    if qing_group.parent.nil?
      answer_group.new_rank = 1
    else
      parent_answer_group = lookup(qing_group.parent) || build_answer_group(qing_group.parent)
      parent_answer_group.children << answer_group
      answer_group.new_rank = parent_answer_group.children.length
    end
  end
end
