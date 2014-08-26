# a subset of QuestionSummaries tied to a particular disaggregation value
# e.g., if the report is disaggregated by the answer to the 'urban/rural' question,
# there would be two SummarySubsets:
# 1:  :disaggregation_value => Option(:name => 'urban'), :summaries => [summary1, summary2, ...]
# 2:  :disaggregation_value => Option(:name => 'rural'), :summaries => [summary1, summary2, ...]
class Report::SummarySubset
  attr_reader :disagg_value, :summaries, :groups

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    @summaries ||= []

    # if all summaries have no items (are empty), set the empty flag
    @no_data = summaries.all?(&:empty?)
  end

  def no_data?
    @no_data
  end

  def append_summaries(summaries)
    @summaries += summaries
  end

  def build_groups(options)
    @groups = Report::SummaryGroup.generate(summaries, :order => options[:question_order] || 'number')
  end

  def as_json(options = {})
    # assumes disagg_value is nil or an Option
    # don't need to include summaries as they're in the groups
    {
      :groups => groups,
      :disagg_value => disagg_value.nil? ? nil : disagg_value.as_json(:only => [:id], :methods => :name),
      :no_data => no_data?
    }
  end
end