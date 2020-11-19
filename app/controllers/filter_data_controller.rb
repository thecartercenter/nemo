# frozen_string_literal: true

# Non-RESTful, JSON-only controller that provides data for the filter components.
# Cuts across multiple models and builds a data structure needed by the view.
class FilterDataController < ApplicationController
  # Returns a sorted list of Questionings that appear on the given forms and are referencable
  # from a search query. If a Question appears on multiple forms, only the first Questioning is returned.
  # The information about the form is not important in this case.
  def qings
    authorize!(:index, Response)
    qings = Questioning.for_mission(current_mission).joins(:question)
      .includes(:question).with_type_property(:refable).order("questions.code")
    qings = qings.where(form_id: params[:form_ids]) if params[:form_ids].present?
    qings = qings.filter_unique

    # Temporary guard clause to investigate a strange flapping spec.
    # Only running in test mode b/c full_rank call was causing N+1 performance issues
    if Rails.env.test? && (weird = qings.select { |qing| qing.full_rank.empty? }).any?
      pp(weird)
      raise "qing rank should always be non-empty"
    end

    render(json: ConditionalLogicForm::TargetQuestioningSerializer.render_as_json(qings))
  end
end
