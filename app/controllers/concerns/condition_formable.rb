# frozen_string_literal: true

module ConditionFormable
  extend ActiveSupport::Concern

  def condition_params
    [:id, :left_qing_id, :right_qing_id, :right_side_type, :op, :value, :_destroy, option_node_ids: []]
  end

  def human_readable_conditions(codes: true, nums: true)
    decorated_conditions = ConditionDecorator.decorate_collection(condition_group.members)
    concatenator = condition_group.true_if == "all_met" ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map { |c| c.human_readable(codes: codes, nums: nums) }.join(" #{concatenator} ")
  end
end
