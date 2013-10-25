# models a group of summary clusters for a standard form report
class Report::SummaryGroup
  # the type of group this is
  attr_reader :type, :clusters

  # generates a set of groups for the given summaries and options
  # options[:order] - either number or type
  def self.generate(summaries, options)
    # if order is by number, then just go for it
    if options[:order] == 'number'
      [new(:type => :all, :clusters => Report::SummaryCluster.generate(summaries))]

    # else if by type
    else

      # separate summaries by type

      # generate each group
      #types.map{|t| generate(summaries)}
    end
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def as_json(options = {})
    super(:only => [:type, :clusters])
  end
end