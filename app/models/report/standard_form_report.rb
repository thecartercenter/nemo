class Report::StandardFormReport < Report::Report
  belongs_to(:form)

  # returns the number of responses matching the report query
  def response_count
    query.count
  end

  def summaries
    return @summaries if @summaries

    # eager load form
    f = Form.includes({:questionings => [{:question => {:option_set => :options}}, 
      {:answers => [:option, {:choices => :option}]}]}).find(form_id)

    # generate
    @summaries = f.questionings.reject{|qing| qing.hidden?}.map do |qing|
      Report::QuestionSummary.new(:questioning => qing)
    end
  end

  protected

    def prep_query(query)
      query
    end
end
