# a subset of QuestionSummaries tied to a particular disaggregation value
# e.g., if the report is disaggregated by the answer to the 'urban/rural' question,
# there would be two SummarySubsets:
# 1:  :disaggregation_value => Option(:name => 'urban'), :summaries => [summary1, summary2, ...]
# 2:  :disaggregation_value => Option(:name => 'rural'), :summaries => [summary1, summary2, ...]
class Report::SummarySubset
  attr_reader :disagg_value, :summaries

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    @summaries ||= []
    
    # if all summaries have no items (are empty), set the empty flag
    @no_data = summaries.all?{|s| s.items.empty?}
  end

  def no_data?
    @no_data
  end

  def append_summaries(summaries)
    @summaries += summaries
  end

  def as_json(options = {})
    super(:only => [:disagg_value, :summaries])
  end
end