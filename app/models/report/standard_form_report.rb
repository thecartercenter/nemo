class Report::StandardFormReport < Report::Report
  belongs_to(:form)

  # returns the number of responses matching the report query
  def response_count
    query.count
  end

  def summaries
    return @summaries if @summaries

    # generate
    @summaries = form.questionings.visible.map do |qing|
      Report::QuestionSummary.new(:questioning => qing)
    end
  end

  protected

    def prep_query(query)
      # default is fine for now
      query
    end
end
