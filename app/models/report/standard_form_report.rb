class Report::StandardFormReport < Report::Report
  belongs_to(:form)

  # returns the number of responses matching the report query
  def response_count
    query.count
  end

  protected

    def prep_query(query)
      # default is fine for now
      query
    end
end
