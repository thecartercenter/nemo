# models a summary of the answers for a question on a form
class Report::QuestionSummary
  attr_reader :questioning, :items

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    # get non-blank values
    values = questioning.answers.reject{|a| a.value.blank?}.map(&:value)

    if values.empty?
      @items = nil
    else
      # convert values appropriately
      values = values.map(&(questioning.qtype.name == 'integer' ? :to_i : :to_f))

      # add the descriptive statistics methods
      values = values.extend(DescriptiveStatistics)

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