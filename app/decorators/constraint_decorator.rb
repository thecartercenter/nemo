# frozen_string_literal: true

# Generates human readable representation of Constraints
class ConstraintDecorator < ApplicationDecorator
  delegate_all
  include ConditionalLogicDecorable

  def human_readable
    I18n.t("constraint.instructions", conditions: human_readable_conditions)
  end

  def read_only_header
    I18n.t("constraint.accept_if_options.#{accept_if}")
  end
end
