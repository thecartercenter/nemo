# frozen_string_literal: true

module ResponseFormConditionalLogic
  # Serializes condition for response web form display logic
  class ConditionSerializer < ApplicationSerializer
    fields :left_qing_id, :op, :value, :option_node_id
    field :right_side_is_qing?, name: :right_side_is_qing
    field :right_qing_id
  end
end
