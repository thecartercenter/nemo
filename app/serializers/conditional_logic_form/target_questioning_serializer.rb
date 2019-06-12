# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Questionings for cases where they are targets of conditional logic, like left_qing/right_qing.
  class TargetQuestioningSerializer < ApplicationSerializer
    attributes :id, :code, :rank, :full_dotted_rank, :qtype_name, :textual, :numeric, :option_set_id

    def textual
      object.textual?
    end

    def numeric
      object.numeric?
    end
  end
end
