# frozen_string_literal: true

# Generates human readable representation of Skip Rules
class SkipRuleDecorator < ApplicationDecorator
  delegate_all

  def human_readable
    I18n.t("question.skip_rule_instructions",
      name_and_rank: QuestioningDecorator.new(dest_item).name_and_rank,
      conditions: decorate_conditions)
  end

  def decorate_conditions
    decorated_conditions = ConditionDecorator.decorate_collection(condition_group.members)
    concatenator = condition_group.true_if == "all_met" ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map(&:human_readable).join(" #{concatenator} ")
  end
end
