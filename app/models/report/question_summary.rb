# models a summary of the answers for a question on a form
class Report::QuestionSummary
  attr_reader :questioning, :items

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    # build the summary
    values = questioning.answers.reject{|a| a.value.blank?}.map{|a| a.value.to_f}.extend(DescriptiveStatistics)
    if values.empty?
      @items = nil
    else
      stats_to_compute = [:mean, :median, :max, :min]
      @items = ActiveSupport::OrderedHash[*stats_to_compute.map{|stat| [stat, values.send(stat)]}.flatten]
    end
  end

  def qtype
    questioning.qtype
  end

  def empty?
    items.nil?
  end
end