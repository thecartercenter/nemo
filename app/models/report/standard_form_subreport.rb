# models a disaggregated subsection of a standard form report
# such reports may have several of these, or just one if no disaggregation was requested
class Report::StandardFormSubreport
  attr_reader :parent, :summaries, :groups, :disagg_value

  # generates a set of subreports based on the given SummaryCollection
  # attribs[:parent] - the parent StandardFormReport
  def self.generate(summary_collection, attribs)
    # for each SummarySubset in the collection, create a subreport
    summary_collection.subsets.map do |subset|
      groups = Report::SummaryGroup.generate(subset.summaries, :order => attribs[:parent].question_order)
      new(attribs.merge(:disagg_value => subset.disagg_value, :summaries => subset.summaries, :groups => groups))
    end
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def as_json(options = {})
    # assumes disagg_value is nil or an Option
    {:groups => groups, :disagg_value => disagg_value.nil? ? nil : disagg_value.as_json(:only => [:id], :methods => :name)}
  end
end
