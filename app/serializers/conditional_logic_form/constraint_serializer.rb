# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Constraints for use in constraint form.
  class ConstraintSerializer < ApplicationSerializer
    fields :id, :accept_if, :rank, :rejection_msg_translations
    association :conditions, blueprint: ConditionSerializer
  end
end
