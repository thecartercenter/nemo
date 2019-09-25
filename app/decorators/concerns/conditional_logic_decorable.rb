# frozen_string_literal: true

module ConditionalLogicDecorable
  extend ActiveSupport::Concern

  def human_readable_conditions(codes: true, nums: true)
    decorated_conditions = ConditionDecorator.decorate_collection(condition_group.members)
    concatenator = condition_group.true_if == "all_met" ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map { |c| c.human_readable(codes: codes, nums: nums) }.join(" #{concatenator} ")
  end
end
