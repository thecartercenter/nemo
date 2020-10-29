# frozen_string_literal: true

module ConditionFormable
  extend ActiveSupport::Concern

  def condition_params
    [:id, :left_qing_id, :right_qing_id, :right_side_type, :op, :value, :_destroy, {option_node_ids: []}]
  end
end
