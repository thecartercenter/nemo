# an collection of SummarySubsets
# see SummarySubset for more info
class Report::SummaryCollection
  attr_reader :subsets

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end
end