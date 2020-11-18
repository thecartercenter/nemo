# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes FormItems for cases where they are targets of conditional logic, like dest_item.
  class TargetFormItemSerializer < ApplicationSerializer
    fields :id, :code, :rank, :full_dotted_rank
  end
end
