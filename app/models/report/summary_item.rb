# models one cell of a question summary for a standard form report
class Report::SummaryItem
  attr_accessor :stat, :text, :count, :pct, :response_id, :qtype_name, :created_at, :submitter_name

  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def as_json(options = {})
    super(:only => [:qtype_name, :stat, :text, :count, :pct, :response_id, :created_at, :submitter_name])
  end
end