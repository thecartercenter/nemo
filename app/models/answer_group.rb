# frozen_string_literal: true

# Corresponds with a QingGroup
# An AnswerGroups's parent is an AnswerGroupSet or an AnswerGroup.
# Its children can be Answers, AnswerSets, AnswerGroups, or AnswerGroupSets.
class AnswerGroup < ResponseNode
  belongs_to :questioning, class_name: 'QingGroup'
end
