# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Constraints for use in constraint form.
  class ConstraintSerializer < ApplicationSerializer
    attributes :id, :accept_if, :rank
    has_many :conditions, serializer: ConditionSerializer
  end
end
