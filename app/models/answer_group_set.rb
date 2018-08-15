# frozen_string_literal: true

# Corresponds with a Repeat Qing Group
# An AnswerGroupSet's parent is an AnswerGroup.
# Its children are AnswerGroups.
class AnswerGroupSet < ResponseNode
  def name
    form_item.group_name
  end
end
