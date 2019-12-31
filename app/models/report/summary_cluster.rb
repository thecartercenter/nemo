# frozen_string_literal: true

# models a cluster of question summaries for a standard form report
# a cluster is a set of questions with the same qtype and option set or other headings
class Report::SummaryCluster
  attr_reader :summaries, :headers, :display_type, :overall_header

  # generates a set of clusters for the given summaries
  def self.generate(summaries)
    [].tap do |clusters|
      summaries.each do |s|
        # if this summary doesn't fit with the current cluster,
        # or if there is no current cluster, create a new one
        if clusters.last&.accepts(s)
          clusters.last.add(s)
        else
          clusters << new(s)
        end
      end
    end
  end

  # initialize takes a summary which should be included and which defines the cluster
  def initialize(first_summary)
    @summaries = []
    @headers = first_summary.headers
    @display_type = first_summary.display_type
    @overall_header = first_summary.overall_header
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

  def as_json(_options = {})
    {
      summaries: summaries,
      headers: headers,
      display_type: display_type,
      overall_header: overall_header
    }
  end
end
