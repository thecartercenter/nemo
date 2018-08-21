# frozen_string_literal: true

# Corresponds with a Repeat Qing Group
# An AnswerGroupSet's parent is an AnswerGroup.
# Its children are AnswerGroups.
class AnswerGroupSet < ResponseNode
  alias qing_group form_item

  def name
    qing_group.group_name
  end
end
