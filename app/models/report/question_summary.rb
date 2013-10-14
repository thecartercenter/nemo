# models a summary of the answers for a question on a form
class Report::QuestionSummary
  attr_reader :questioning, :items, :null_count

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    case questioning.qtype_name
    when 'integer', 'decimal'

      # get non-blank values and set null count
      values = questioning.answers.reject{|a| a.value.blank?}.map(&:value)
      @null_count = questioning.answers.size - values.size

      if values.empty?
        # no statistics make sense in this case
        @items = {}
      else
        # convert values appropriately
        values = values.map(&(questioning.qtype.name == 'integer' ? :to_i : :to_f))

        # add the descriptive statistics methods
        values = values.extend(DescriptiveStatistics)

        stats_to_compute = [:mean, :median, :max, :min]
        @items = ActiveSupport::OrderedHash[*stats_to_compute.map{|stat| [stat, values.send(stat)]}.flatten]
      end

    when 'select_one', 'select_multiple'
      # init tallies to zero
      @items = ActiveSupport::OrderedHash[*questioning.options.map{|o| [o, 0]}.flatten]
      @null_count = 0

      # build tallies
      questioning.answers.each do |ans| 
        # build tally differently depending on if one or multiple
        if questioning.qtype_name == 'select_one'
          ans.option.nil? ? (@null_count += 1) : (@items[ans.option] += 1)
        else
          # we need to loop over choices
          # there are no nulls in a select_multiple (choice.option should never be nil)
          ans.choices.each{|choice| @items[choice.option] += 1 unless choice.option.nil?}
        end
      end

    end
  end

  def qtype
    questioning.qtype
  end
end