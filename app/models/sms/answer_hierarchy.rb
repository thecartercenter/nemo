class Sms::AnswerHierarchy
  def initialize
    # mapping from qing group ID -> answer group
    @answer_groups = {}
  end

  def lookup(qing_group)
    @answer_groups[qing_group.id]
  end

  def answer_group_for(qing)
    qing_group = qing.parent
    answer_group = lookup(qing_group) || build_answer_group(qing_group)

    if qing.multilevel?
      answer_set = AnswerSet.new(form_item: qing)
      answer_group.children << answer_set
      answer_group = answer_set
    end

    answer_group
  end

  private

  def build_answer_group(qing_group)
    answer_group = AnswerGroup.new(form_item: qing_group)
    link(answer_group)
    @answer_groups[qing_group.id] = answer_group
    answer_group
  end

  def link(answer_group)
    qing_group = answer_group.form_item

    unless qing_group.parent.nil?
      parent_answer_group = lookup(qing_group.parent)
      parent_answer_group.children << answer_group
    end
  end
end
