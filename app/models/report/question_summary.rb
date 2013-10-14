# models a summary of the answers for a question on a form
class Report::QuestionSummary
  # the questioning we're summarizing
  attr_reader :questioning
    
  # the individual items of information in the summary. can be an ordered hash or an array
  attr_reader :items

  # the number of null answers we encountered
  attr_reader :null_count

  # the number of choices as opposed to answers, we encountered (only set for select_multiple questions)
  attr_reader :choice_count

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
      
      if questioning.qtype_name == 'select_multiple'
        @choice_count = 0 
        questioning.answers.each do |ans|
          # we need to loop over choices
          # there are no nulls in a select_multiple (choice.option should never be nil)
          ans.choices.each do |choice|
            unless choice.option.nil?
              @items[choice.option] += 1
              @choice_count += 1
            end
          end
        end

      else # select_one
        questioning.answers.each do |ans|
          ans.option.nil? ? (@null_count += 1) : (@items[ans.option] += 1)
        end
      end

    when 'date'
      # init tallies to zero
      @items = ActiveSupport::OrderedHash.new
      @null_count = 0

      # build tallies
      questioning.answers.each do |a| 
        if a.nil?
          @null_count += 1
        else
          @items[a.date_value] ||= 0
          @items[a.date_value] += 1
        end
      end
      
      # sort keys

    end
  end

  def qtype
    questioning.qtype
  end
end