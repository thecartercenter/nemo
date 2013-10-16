# models a summary of the answers for a question on a form
class Report::QuestionSummary
  # the questioning we're summarizing
  attr_reader :questioning
    
  # array containing the individual items of information in the summary
  attr_reader :items

  # the column headers, if any
  attr_reader :headers

  # the number of null answers we encountered
  attr_reader :null_count

  # the number of choices as opposed to answers, we encountered (only set for select_multiple questions)
  attr_reader :choice_count

  attr_reader :display_type
  attr_reader :overall_header

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    case questioning.qtype_name

    # these types all get descriptive statistics
    when 'integer', 'decimal', 'time', 'datetime'
      @display_type = :structured

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

        @headers = [:mean, :median, :max, :min]
        @items = @headers.map{|stat| Report::SummaryItem.new(:stat => values.send(stat))}

        # if temporal, convert back to Times
        case questioning.qtype_name
        when 'time' then @items.each{|i| i.stat = Time.at(i.stat)}
        when 'datetime' then @items.each{|i| i.stat = Time.zone.at(i.stat)}
        end
      end

    when 'select_one', 'select_multiple'
      @display_type = :structured
      @overall_header = questioning.option_set.name

      # init tallies to zero
      @items = ActiveSupport::OrderedHash[*questioning.options.map{|o| [o, Report::SummaryItem.new(:count => 0)]}.flatten]
      @null_count = 0
      
      if questioning.qtype_name == 'select_multiple'
        @choice_count = 0 
        questioning.answers.each do |ans|
          # we need to loop over choices
          # there are no nulls in a select_multiple (choice.option should never be nil)
          ans.choices.each do |choice|
            unless choice.option.nil?
              @items[choice.option].count += 1
              @choice_count += 1
            end
          end
        end

      else # select_one
        questioning.answers.each do |ans|
          ans.option.nil? ? (@null_count += 1) : (@items[ans.option].count += 1)
        end
      end

      # split items hash into keys and values
      @headers = @items.keys
      @items = @items.values

      compute_percentages

    when 'date'
      @display_type = :structured
      @overall_header = I18n.t('report/report.standard_form_report.overall_headers.dates')

      # init tallies to zero
      @items = ActiveSupport::OrderedHash.new

      # we compute this directly and use to_a so as not to trigger an additional db query
      @null_count = questioning.answers.to_a.count{|a| a.date_value.nil?}

      # build tallies
      questioning.answers.reject{|a| a.date_value.nil?}.sort_by{|a| a.date_value}.each do |a| 
        if a.date_value.nil?
          @null_count += 1
        else
          @items[a.date_value] ||= Report::SummaryItem.new(:count => 0)
          @items[a.date_value].count += 1
        end
      end

      # split items hash into keys and values
      @headers = @items.keys
      @items = @items.values

      compute_percentages

    when 'text', 'tiny_text', 'long_text'
      @display_type = :flow
      @overall_header = I18n.t('report/report.standard_form_report.overall_headers.responses')

      # reject nil answers and sort by response date
      answers = questioning.answers.reject(&:nil_value?)
      answers.sort_by!{|a| a.response.created_at}

      # get items and headers
      @headers = questioning.qtype_name == 'long_text' ? [:long_responses] : [:responses]
      @items = answers.map{|a| Report::SummaryItem.new(:text => a.casted_value, :response => a.response)}

      # nulls are stripped out so we can calculate how many just by taking difference
      @null_count = questioning.answers.size - @items.size
    end
  end

  def qtype
    questioning.qtype
  end

  # gets a set of objects that allow this summary to be compared to others for clustering
  def signature
    [questioning.option_set, headers]
  end

  def compute_percentages
    denominator = (questioning.answers.size - null_count).to_f
    items.each do |item|
      item.pct = denominator == 0 ? 0 : item.count.to_f / denominator * 100
    end
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