# frozen_string_literal: true

# Generates human readable representation of Constraints
class ConstraintDecorator < ApplicationDecorator
  delegate_all

  def human_readable
    I18n.t("constraint.instructions", conditions: human_readable_conditions)
  end

  def read_only_header
    I18n.t("constraint.accept_if_options.#{accept_if}")
  end

  private

  def human_readable_conditions
    decorated_conditions = ConditionDecorator.decorate_collection(condition_group.members)
    concatenator = condition_group.true_if == "all_met" ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map { |c| c.human_readable(include_code: true) }.join(" #{concatenator} ")
  end
end
