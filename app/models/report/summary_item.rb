# models one cell of a question summary for a standard form report
class Report::SummaryItem
  attr_accessor :stat, :text, :count, :pct, :response
  
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def as_json(options = {})
    h = super(:only => [:stat, :text, :count, :pct])
    h[:response] = response.as_json(:only => [:id, :user_id, :created_at])
    h
  end
end