# models a group of summary clusters for a standard form report
class Report::SummaryGroup
  # the type of group this is
  attr_reader :type, :clusters

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end
end