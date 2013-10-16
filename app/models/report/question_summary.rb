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

    # these types all get descriptive statistics
    when 'integer', 'decimal', 'time', 'datetime'

      # get non-blank values and set null count
      values = questioning.answers.map(&:casted_value).compact
      @null_count = questioning.answers.size - values.size

      if values.empty?
        # no statistics make sense in this case
        @items = {}
      else
        # add the descriptive statistics methods
        values = values.extend(DescriptiveStatistics)

        # if temporal question type, convert values unix timestamps before running stats
        values.map!(&:to_i) if questioning.qtype.temporal?

        stats_to_compute = [:mean, :median, :max, :min]
        @items = ActiveSupport::OrderedHash[*stats_to_compute.map{|stat| [stat, values.send(stat)]}.flatten]

        # if temporal, convert back to Times
        case questioning.qtype_name
        when 'time' then @items.each{|k,v| @items[k] = Time.at(v)}
        when 'datetime' then @items.each{|k,v| @items[k] = Time.zone.at(v)}
        end
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

      # we compute this directly and use to_a so as not to trigger an additional db query
      @null_count = questioning.answers.to_a.count{|a| a.date_value.nil?}

      # build tallies
      questioning.answers.reject{|a| a.date_value.nil?}.sort_by{|a| a.date_value}.each do |a| 
        if a.date_value.nil?
          @null_count += 1
        else
          @items[a.date_value] ||= 0
          @items[a.date_value] += 1
        end
      end

    when 'text', 'tiny_text', 'long_text'
      # reject nil answers and sort by response date
      answers = questioning.answers.reject(&:nil_value?)
      answers.sort_by!{|a| a.response.created_at}

      # get items
      @items = answers.map{|a| {:text => a.casted_value, :response => a.response.as_json(:only => [:id, :created_at])}}

      # nulls are stripped out so we can calculate how many just by taking difference
      @null_count = questioning.answers.size - @items.size
    end
  end

  def qtype
    questioning.qtype
  end

  def as_json(options = {})
    h = super(options)
    h[:questioning] = questioning.as_json(:only => [:id])
    h[:items] = items
    h[:null_count] = null_count
    h[:choice_count] = choice_count
    h
  end
end