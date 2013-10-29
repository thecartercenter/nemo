class Report::SummaryCollection
  attr_reader :subsets, :questionings

  def self.merge(collections)
    collections.first
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

end