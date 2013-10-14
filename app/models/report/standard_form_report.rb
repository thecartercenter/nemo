class Report::StandardFormReport < Report::Report
  belongs_to(:form)

  # question types that we leave off this report (stored as a hash for better performance)
  EXCLUDED_TYPES = {'location' => true}

  # returns the number of responses matching the report query
  def response_count
    query.count
  end

  # returns an array of question summaries ordered by question rank
  def summaries
    return @summaries if @summaries

    # eager load form
    f = Form.includes({:questionings => [{:question => {:option_set => :options}}, 
      {:answers => [:option, {:choices => :option}]}]}).find(form_id)

    # generate
    @summaries = f.questionings.reject{|qing| qing.hidden? || EXCLUDED_TYPES[qing.qtype.name]}.map do |qing|
      Report::QuestionSummary.new(:questioning => qing)
    end
  end

  protected

    def prep_query(query)
      query
    end
end
