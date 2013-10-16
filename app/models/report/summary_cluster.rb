# models a cluster of question summaries for a standard form report
# a cluster is a set of questions with the same qtype and option set or other headings
class Report::SummaryCluster
  attr_reader :summaries, :headers

  # initialize takes a summary which should be included and which defines the cluster
  def initialize(first_summary)
    @summaries = []
    @headers = first_summary.headers
    add(first_summary)
  end

  # adds a summary
  def add(summary)
    @summaries << summary
  end

  # checks if the given summary can be added to the current cluster
  def accepts(summary)
    summary.signature == summaries.first.signature
  end

  def as_json(options = {})
    super(:only => [:summaries, :headers])
  end
end