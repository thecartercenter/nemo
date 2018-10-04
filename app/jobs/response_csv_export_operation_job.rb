class ResponseCsvExportOperationJob < OperationJob
  def perform(operation, mission, search = nil)
    ability = Ability.new(user: operation.creator, mission: mission)
    responses = Response.accessible_by(ability, :export)

    # do search, excluding excerpts
    if search.present?
      responses = Response.do_search(
        responses,
        search,
        {mission: mission},
        include_excerpts: false
      )
    end

    # Get the response, for export, but not paginated.
    # We deliberately don't eager load as that is handled in the Results::Csv::Generator class.
    responses = responses.order(:created_at)

    csv = Results::Csv::Generator.new(responses)
    result = csv.export
    operation_succeeded(File.open(result))
  rescue Search::ParseError => error
    operation_failed(error.to_s)
  end
end
