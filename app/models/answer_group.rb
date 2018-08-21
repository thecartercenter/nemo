# frozen_string_literal: true

# Corresponds with a QingGroup
# An AnswerGroups's parent is an AnswerGroupSet or an AnswerGroup.
# Its children can be Answers, AnswerSets, AnswerGroups, or AnswerGroupSets.
class AnswerGroup < ResponseNode
  alias qing_group form_item
  delegate :group_hint, to: :form_item

  def repeatable?
    parent.is_a?(AnswerGroupSet)
  end
end
