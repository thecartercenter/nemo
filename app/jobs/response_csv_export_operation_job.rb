# frozen_string_literal: true

# Operation for exporting response CSV.
class ResponseCSVExportOperationJob < OperationJob
  def perform(operation, search: nil, options: {})
    ability = Ability.new(user: operation.creator, mission: mission)
    attachment = generate_csv(
      responses(ability, search, selected: options[:selected]),
      long_text_behavior: options[:long_text_behavior]
    )
    timestamp = Time.current.to_s(:filename_datetime)
    save_attachment(attachment, "#{mission.compact_name}-responses-#{timestamp}.csv")
  rescue Search::ParseError => e
    operation_failed(e.to_s)
  end

  private

  def responses(ability, search, selected:)
    responses = Response.accessible_by(ability, :export)
    responses = apply_search_scope(responses, search, mission) if search.present?
    responses = responses.where(id: selected) if selected.present?

    # Get the response, for export, but not paginated.
    # We deliberately don't eager load as that is handled in the Results::CSV::Generator class.
    responses.order(:created_at)
  end

  def apply_search_scope(responses, search, mission)
    ResponsesSearcher.new(relation: responses, query: search, scope: {mission: mission}).apply
  end

  def generate_csv(responses, long_text_behavior:)
    Results::CSV::Generator.new(responses, long_text_behavior: long_text_behavior, mission: mission).export
  end
end
