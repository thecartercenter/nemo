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

  def self.generate_for(questionings)
    @summaries = []

    # split questionings by type
    stat_qings = questionings.find_all{|qing| %w(integer decimal time datetime).include?(qing.qtype_name)}

    # take all statistic type questions and get data
    @summaries += generate_for_statistic_questionings(stat_qings)

    # @summaries += generate_for_select_questionings(tally_qings)

    # @summaries += generate_for_date_questionings(date_qings)

    # @summaries += generate_for_raw_questionings(raw_qings)

    @summaries
  end

  def self.generate_for_statistic_questionings(questionings)
    return [] if questionings.empty?

    qing_ids = questionings.map(&:id).join(',')
    qings_by_id = questionings.index_by(&:id)

    # build big query
    query = <<-eos
      SELECT qing.id AS qing_id, q.qtype_name AS qtype_name,
        SUM(
          CASE q.qtype_name
            WHEN 'integer' THEN IF(a.value IS NULL OR a.value = '', 1, 0)
            WHEN 'decimal' THEN IF(a.value IS NULL OR a.value = '', 1, 0)
            WHEN 'time' THEN IF(a.time_value IS NULL, 1, 0)
            WHEN 'datetime' THEN IF(a.datetime_value IS NULL, 1, 0)
          END
        ) AS null_count,
        CASE q.qtype_name
          WHEN 'integer' THEN AVG(CONVERT(a.value, SIGNED INTEGER)) 
          WHEN 'decimal' THEN AVG(CONVERT(a.value, DECIMAL(9,6)))
          WHEN 'time' THEN SEC_TO_TIME(AVG(TIME_TO_SEC(a.time_value)))
          WHEN 'datetime' THEN FROM_UNIXTIME(AVG(UNIX_TIMESTAMP(a.datetime_value)))
        END AS mean,
        CASE q.qtype_name
          WHEN 'integer' THEN MIN(CONVERT(a.value, SIGNED INTEGER)) 
          WHEN 'decimal' THEN MIN(CONVERT(a.value, DECIMAL(9,6)))
          WHEN 'time' THEN MIN(a.time_value)
          WHEN 'datetime' THEN MIN(a.datetime_value)
        END AS min,
        CASE q.qtype_name
          WHEN 'integer' THEN MAX(CONVERT(a.value, SIGNED INTEGER)) 
          WHEN 'decimal' THEN MAX(CONVERT(a.value, DECIMAL(9,6)))
          WHEN 'time' THEN MAX(a.time_value)
          WHEN 'datetime' THEN MAX(a.datetime_value)
        END AS max
      FROM answers a INNER JOIN questionings qing ON a.questioning_id = qing.id AND qing.id IN (#{qing_ids}) 
        INNER JOIN questions q ON q.id = qing.question_id 
      WHERE q.qtype_name in ('integer', 'decimal', 'time', 'datetime') GROUP BY qing.id, q.qtype_name
    eos

    res = ActiveRecord::Base.connection.execute(query)
    stats = %w(mean min max)

    # build headers
    headers = stats.map{|s| {:name => I18n.t("report/report.standard_form_report.stat_headers.#{s}"), :stat => s.to_sym}}

    summaries = res.each(:as => :hash).map do |row|
      qing = qings_by_id[row['qing_id']]

      # if mean is nil, means no non-nil values
      if row['mean'].nil?

        items = {}
      else
        # convert stats to appropriate type
        case qing.qtype_name
        when 'integer'
          row['mean'] = row['mean'].to_f
          %w(max min).each{|s| row[s] = row[s].to_i}
        when 'decimal'
          %w(mean max min).each{|s| row[s] = row[s].to_f}
        when 'time'
          %w(mean max min).each{|s| row[s] = I18n.l(Time.parse(row[s]), :format => :time_only)}
        when 'datetime'
          %w(mean max min).each{|s| row[s] = I18n.l(Time.zone.parse(row[s] + ' UTC'))}
        end

        # build items
        items = stats.map{|stat| Report::SummaryItem.new(:qtype_name => row['qtype_name'], :stat => row[stat])}
      end

      # build summary
      new(:questioning => qings_by_id[row['qing_id']], :display_type => :structured, :headers => headers, :items => items, :null_count => row['null_count'])
    end

    # build blank summaries for missing qings
    already_summarized = summaries.map(&:questioning)
    summaries += (questionings - already_summarized).map do |qing|
      new(:questioning => qing, :display_type => :structured, :headers => headers, :items => {}, :null_count => 0)
    end

    summaries
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    qtype_name = questioning.qtype_name
    case qtype_name

    # these types all get descriptive statistics
    when nil
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

        stats = [:mean, :median, :max, :min]
        @headers = stats.map{|s| {:name => I18n.t("report/report.standard_form_report.stat_headers.#{s}"), :stat => s}}
        @items = stats.map{|stat| Report::SummaryItem.new(:qtype_name => qtype_name, :stat => values.send(stat))}

        # if temporal, convert back to Times and convert to a nice string
        case questioning.qtype_name
        when 'time' then @items.each{|i| i.stat = I18n.l(Time.at(i.stat).utc, :format => :time_only)}
        when 'datetime' then @items.each{|i| i.stat = I18n.l(Time.zone.at(i.stat))}
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
      @headers = @items.keys.map{|option| {:name => option.name, :option => option}}
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
      @headers = @items.keys.map{|date| {:name => I18n.l(date), :date => date}}
      @items = @items.values

      compute_percentages

    when 'text', 'tiny_text', 'long_text'
      @overall_header = I18n.t('report/report.standard_form_report.overall_headers.responses')
      @headers = []

      # reject nil answers and sort by response date
      answers = questioning.answers.reject(&:nil_value?)
      answers.sort_by!{|a| a.response.created_at}

      # get items
      @items = answers.map{|a| Report::SummaryItem.new(:text => a.casted_value, :response => a.response)}

      # nulls are stripped out so we can calculate how many just by taking difference
      @null_count = questioning.answers.size - @items.size

      # display type is only 'full_width' if long text
      @display_type = questioning.qtype_name == 'long_text' ? :full_width : :flow
    end
  end

  def qtype
    questioning.qtype
  end

  # gets a set of objects that allow this summary to be compared to others for clustering
  def signature
    [display_type, questioning.option_set, headers]
  end

  def compute_percentages
    denominator = (questioning.answers.size - null_count).to_f
    items.each do |item|
      item.pct = denominator == 0 ? 0 : item.count.to_f / denominator * 100
    end
  end

  def as_json(options = {})
    h = super(options)
    h[:questioning] = questioning.as_json(
      :only => [:id, :rank], 
      :methods => [:code, :name, :referring_condition_ranks], 
      :include => {:condition => {:only => [], :methods => :to_s}}
    )
    h[:items] = items
    h[:null_count] = null_count
    h[:choice_count] = choice_count
    h
  end
end