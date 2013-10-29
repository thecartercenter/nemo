class Report::SummaryCollection
  attr_reader :subsets, :questionings

  def self.merge(collections)
    collections.first
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    # if all subsets are no_data, the whole collection is no_data!
    @no_data = subsets.all?{|s| s.no_data?}
  end

  def no_data?
    @no_data
  end
end