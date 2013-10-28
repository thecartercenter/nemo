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

  attr_reader :display_type
  attr_reader :overall_header

  def self.generate_for(questionings)
    @summaries = []

    # split questionings by type
    type_to_group = {
      'integer' => 'stat',
      'decimal' => 'stat',
      'time' => 'stat',
      'datetime' => 'stat',
      'select_one' => 'select',
      'select_multiple' => 'select',
      'date' => 'date',
      'text' => 'raw',
      'tiny_text' => 'raw',
      'long_text' => 'raw'
    }

    grouped = {'stat' => [], 'select' => [], 'date' => [], 'raw' => []}

    questionings.each{|qing| grouped[type_to_group[qing.qtype_name]] << qing}

    # take all statistic type questions and get data
    @summaries += generate_for_statistic_questionings(grouped['stat'])

    @summaries += generate_for_select_questionings(grouped['select'])

    @summaries += generate_for_date_questionings(grouped['date'])

    @summaries += generate_for_raw_questionings(grouped['raw'])

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

  def self.generate_for_select_questionings(questionings)
    return [] if questionings.empty?

    qing_ids = questionings.map(&:id).join(',')

    # build and run queries for select_one and _multiple
    query = <<-eos
      SELECT qings.id AS qing_id, a.option_id AS option_id, COUNT(a.id) AS answer_count 
      FROM questionings qings 
        INNER JOIN questions q ON qings.question_id = q.id 
        LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
        WHERE q.qtype_name IN ('select_one', 'select_multiple')
          AND qings.id IN (#{qing_ids})
        GROUP BY qings.id, a.option_id
    eos
    sel_one_res = ActiveRecord::Base.connection.execute(query)
    
    query = <<-eos
      SELECT qings.id AS qing_id, c.option_id AS option_id, COUNT(c.id) AS choice_count 
      FROM questionings qings 
        INNER JOIN questions q ON qings.question_id = q.id 
        LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
        LEFT OUTER JOIN choices c ON a.id = c.answer_id
        WHERE q.qtype_name = 'select_multiple'
          AND qings.id IN (#{qing_ids})
        GROUP BY qings.id, c.option_id
    eos
    sel_mult_res = ActiveRecord::Base.connection.execute(query)

    # read tallies into hashes
    tallies = {}
    sel_one_res.each(:as => :hash).each do |row|
      tallies[[row['qing_id'], row['option_id']]] = row['answer_count']
    end
    sel_mult_res.each(:as => :hash).each do |row|
      tallies[[row['qing_id'], row['option_id']]] = row['choice_count']
    end

    # get the non-null answer counts for sel mult questions
    query = <<-eos
      SELECT qings.id AS qing_id, COUNT(DISTINCT a.id) AS non_null_answer_count 
      FROM questionings qings 
        INNER JOIN questions q ON qings.question_id = q.id 
        LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
        LEFT OUTER JOIN choices c ON a.id = c.answer_id
        WHERE q.qtype_name = 'select_multiple'
          AND qings.id IN (#{qing_ids})
          AND c.id IS NOT NULL
        GROUP BY qings.id
    eos
    sel_mult_non_null_res = ActiveRecord::Base.connection.execute(query)

    # read non-null answer counts into hash
    sel_mult_non_null_tallies = {}
    sel_mult_non_null_res.each(:as => :hash).each do |row|
      sel_mult_non_null_tallies[row['qing_id']] = row['non_null_answer_count']
    end

    # loop over each questioning and generate summary
    questionings.map do |qing|

      # build headers
      headers = qing.options.map{|option| {:name => option.name, :option => option}}

      # build tallies, keeping a running sum
      non_null_count = 0
      items = qing.options.map do |o|
        count = tallies[[qing.id, o.id]] || 0
        non_null_count += count
        Report::SummaryItem.new(:count => count)
      end

      # if this is a sel mult question, the non_null_count we summed reflects the total number of non_null choices, not answers
      # but to compute percentages, we are interested in the non-null answer value, so get it from the hash we built above
      non_null_count = sel_mult_non_null_tallies[qing.id] if qing.qtype_name == 'select_multiple'

      # compute percentages
      items.each do |item|
        item.pct = non_null_count == 0 ? 0 : item.count.to_f / non_null_count * 100
      end

      # null count should be zero for sel multiple b/c no selection can be a valid answer
      null_count = qing.qtype_name == 'select_one' ? tallies[[qing.id, nil]] : 0

      new(:questioning => qing, :display_type => :structured, :overall_header => qing.option_set.name, 
        :headers => headers, :items => items, :null_count => null_count)
    end
  end


  def self.generate_for_date_questionings(questionings)
    return [] if questionings.empty?

    qing_ids = questionings.map(&:id).join(',')

    # build and run query
    query = <<-eos
      SELECT qings.id AS qing_id, a.date_value AS date, COUNT(a.id) AS answer_count 
      FROM questionings qings
        INNER JOIN questions q ON qings.question_id = q.id 
        LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
        WHERE q.qtype_name = 'date'
          AND qings.id IN (#{qing_ids})
        GROUP BY qings.id, a.date_value
        ORDER BY qing_id, date
    eos
    res = ActiveRecord::Base.connection.execute(query)

    # read into tallies
    tallies = {}
    res.each(:as => :hash).each do |row|
      tallies[row['qing_id']] ||= ActiveSupport::OrderedHash[]
      tallies[row['qing_id']][row['date']] = row['answer_count']
    end

    # loop over each questioning and generate summary
    questionings.map do |qing|

      # build headers from tally keys (already sorted)
      headers = (tallies[qing.id] ? tallies[qing.id].keys.reject(&:nil?) : []).map{|date| {:name => I18n.l(date), :date => date}}
      
      # build tallies, keeping a running sum
      non_null_count = 0
      items = headers.map do |h|
        count = tallies[qing.id][h[:date]] || 0
        non_null_count += count
        Report::SummaryItem.new(:count => count)
      end

      # compute percentages
      items.each do |item|
        item.pct = non_null_count == 0 ? 0 : item.count.to_f / non_null_count * 100
      end

      null_count = tallies[qing.id][nil] || 0

      new(:questioning => qing, :display_type => :structured, :overall_header => I18n.t('report/report.standard_form_report.overall_headers.dates'),
        :headers => headers, :items => items, :null_count => null_count)
    end
  end

  def self.generate_for_raw_questionings(questionings)
    return [] if questionings.empty?

    qing_ids = questionings.map(&:id).join(',')

    # # build and run query
    # query = <<-eos
    #   SELECT a.questioning_id AS qing_id, a.value AS text
    #   FROM answers a
    #     WHERE a.questioning_id IN (#{qing_ids})
    #       AND a.value IS NOT NULL
    #       AND a.value != ''
    #     ORDER BY a.created_at
    # eos
    # res = ActiveRecord::Base.connection.execute(query)

    answers = Answer.includes(:response => :user).where(:questioning_id => qing_ids).order('created_at')

    # build summary items and index by qing id, also keep null counts
    items_by_qing_id = {}
    null_counts_by_qing_id = {}
    answers.each do |answer|
      # ensure both initialized
      items_by_qing_id[answer.questioning_id] ||= []
      null_counts_by_qing_id[answer.questioning_id] ||= 0

      # increment null count or add item
      if answer.nil_value?
        null_counts_by_qing_id[answer.questioning_id] += 1
      else
        items_by_qing_id[answer.questioning_id] << Report::SummaryItem.new(:text => answer.value, :response => answer.response)
      end
    end

    # build summaries
    questionings.map do |qing|

      # get items from hash
      items = items_by_qing_id[qing.id] || []

      # display type is only 'full_width' if long text
      display_type = qing.qtype_name == 'long_text' ? :full_width : :flow

      # null count from hash also
      null_count = null_counts_by_qing_id[qing.id] || 0

      new(:questioning => qing, :display_type => display_type, :overall_header => I18n.t('report/report.standard_form_report.overall_headers.responses'),
        :headers => [], :items => items, :null_count => null_count)
    end
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

    when nil
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

    when nil
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

    when nil
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
    h
  end
end