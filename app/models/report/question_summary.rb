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

  # hash for converting qtypes to groups (stat, select, date, raw) used for generating summaries
  QTYPE_TO_SUMMARY_GROUP = {
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

  # generates question summaries for the given questionings
  def self.generate_for(questionings)
    # split questionings by type
    grouped = {'stat' => [], 'select' => [], 'date' => [], 'raw' => []}
    questionings.each{|qing| grouped[QTYPE_TO_SUMMARY_GROUP[qing.qtype_name]] << qing}

    # generate summary collections for each group
    summaries = grouped.keys.map{|g| grouped[g].empty? ? nil : send("generate_for_#{g}_questionings", grouped[g])}.compact.flatten

    # make a summary_collection
    Report::SummaryCollection.new(:subsets => [Report::SummarySubset.new(:disaggregation_value => :all, :summaries => summaries)])
  end

  ####################################################################
  # stat questions
  ####################################################################

  # generates summaries for statistical questions
  # returns a SummarySet object
  def self.generate_for_stat_questionings(questionings)
    # do the query
    res = run_stat_query(questionings)

    # some supporting arrays
    stats = %w(mean min max)
    qings_by_id = questionings.index_by(&:id)

    # build headers
    headers = stats.map{|s| {:name => I18n.t("report/report.standard_form_report.stat_headers.#{s}"), :stat => s.to_sym}}

    # build summaries, one per row of the result set
    summaries = res.each(:as => :hash).map do |row|
      qing = qings_by_id[row['qing_id']]

      # if mean is nil, means no non-nil values
      if row['mean'].nil?

        items = []
      else
        # convert stats to appropriate type
        case qing.qtype_name
        when 'integer'
          row['mean'] = row['mean'].to_f
          %w(max min).each{|s| row[s] = row[s].to_i}
        when 'decimal'
          stats.each{|s| row[s] = row[s].to_f}
        when 'time'
          stats.each{|s| row[s] = I18n.l(Time.parse(row[s]), :format => :time_only)}
        when 'datetime'
          stats.each{|s| row[s] = I18n.l(Time.zone.parse(row[s] + ' UTC'))}
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
      new(:questioning => qing, :display_type => :structured, :headers => headers, :items => [], :null_count => 0)
    end

    summaries
  end

  # builds and executes a query for summary info for stat questions
  # returns a mysql result handle
  def self.run_stat_query(questionings)
    qing_ids = questionings.map(&:id).join(',')

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
    ActiveRecord::Base.connection.execute(query)
  end

  ####################################################################
  # select questions
  ####################################################################

  def self.generate_for_select_questionings(questionings)
    qing_ids = questionings.map(&:id).join(',')

    # get tallies of answers
    tallies = get_select_question_tallies(qing_ids)

    # get tallies of non_null answers for each select multiple question
    sel_mult_non_null_tallies = get_sel_mult_non_null_tallies(qing_ids)

    # loop over each questioning and generate summary
    questionings.map do |qing|

      # build headers
      headers = qing.options.map{|option| {:name => option.name, :option => option}}

      # build tallies, keeping a running sum of non-null answers
      non_null_count = 0
      items = qing.options.map do |o|
        count = tallies[[qing.id, o.id]] || 0
        non_null_count += count
        Report::SummaryItem.new(:count => count)
      end

      # if this is a sel mult question, the non_null_count we summed reflects the total number of non_null choices, not answers
      # but to compute percentages, we are interested in the non-null answer value, so get it from the hash we built above
      non_null_count = sel_mult_non_null_tallies[qing.id] || 0 if qing.qtype_name == 'select_multiple'

      # compute percentages
      items.each do |item|
        item.pct = non_null_count == 0 ? 0 : item.count.to_f / non_null_count * 100
      end

      # null count should be zero for sel multiple b/c no selection can be a valid answer
      null_count = qing.qtype_name == 'select_one' ? tallies[[qing.id, nil]] : 0

      # build summary
      new(:questioning => qing, :display_type => :structured, :overall_header => qing.option_set.name, 
        :headers => headers, :items => items, :null_count => null_count)
    end
  end

  # gets a hash of tallies for each combination of qing_id and option_id for the given select questioning_ids
  def self.get_select_question_tallies(qing_ids)

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

    tallies
  end

  # gets tallies of non-null answers for the given select-multiple qing_ids
  # useful in computing percentages
  def self.get_sel_mult_non_null_tallies(qing_ids)
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
    res = ActiveRecord::Base.connection.execute(query)

    # read non-null answer counts into hash
    tallies = {}
    res.each(:as => :hash).each do |row|
      tallies[row['qing_id']] = row['non_null_answer_count']
    end
    tallies
  end

  ####################################################################
  # date questions
  ####################################################################

  def self.generate_for_date_questionings(questionings)
    # get tallies for each qing and date
    tallies = get_date_question_tallies(questionings)

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

      # get null count from tallies
      null_count = tallies[qing.id][nil] || 0

      # build summary
      new(:questioning => qing, :display_type => :structured, :overall_header => I18n.t('report/report.standard_form_report.overall_headers.dates'),
        :headers => headers, :items => items, :null_count => null_count)
    end
  end

  # gets tallies of dates and answers for each of the given questionings
  def self.get_date_question_tallies(questionings)
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

    # read into tallies, preserving sorted date order
    tallies = {}
    res.each(:as => :hash).each do |row|
      tallies[row['qing_id']] ||= ActiveSupport::OrderedHash[]
      tallies[row['qing_id']][row['date']] = row['answer_count']
    end
    tallies
  end

  ####################################################################
  # date questions
  ####################################################################

  def self.generate_for_raw_questionings(questionings)
    qing_ids = questionings.map(&:id)

    # do answer query
    answers = Answer.where(:questioning_id => qing_ids).order('created_at')

    # get submitter names for long text q's
    submitter_names = get_submiter_names(questionings)

    # build summary items and index by qing id, also keep null counts
    items_by_qing_id = {}
    null_counts_by_qing_id = {}
    answers.each do |answer|
      # ensure both initialized
      items_by_qing_id[answer.questioning_id] ||= []
      null_counts_by_qing_id[answer.questioning_id] ||= 0

      # increment null count or add item
      if answer.value.blank?
        null_counts_by_qing_id[answer.questioning_id] += 1
      else
        item = Report::SummaryItem.new(:text => answer.value)

        # add response info for long text q's
        if name = submitter_names[answer.id]
          item.response_id = answer.response_id
          item.created_at = I18n.l(answer.created_at)
          item.submitter_name = name
        end

        items_by_qing_id[answer.questioning_id] << item
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

      # build summary
      new(:questioning => qing, :display_type => display_type, :overall_header => I18n.t('report/report.standard_form_report.overall_headers.responses'),
        :headers => [], :items => items, :null_count => null_count)
    end
  end

  # gets a hash of answer_id to submitter names for each long_text answer to questionings in the given array
  def self.get_submiter_names(questionings)
    # get ids of long_text q's from the given array
    # (should be eager loaded with Question to avoid n+1)
    long_qing_ids = questionings.find_all{|q| q.qtype_name == 'long_text'}.map(&:id)

    # get submitter info for long text responses and store in hash
    if long_qing_ids.empty?
      {}
    else
      query = <<-eos
        SELECT a.id AS answer_id, u.name AS submitter_name 
        FROM answers a 
          INNER JOIN responses r ON a.response_id = r.id
          INNER JOIN users u ON r.user_id = u.id
        WHERE a.questioning_id IN (#{long_qing_ids.join(',')})
      eos
      res = ActiveRecord::Base.connection.execute(query)
      Hash[*res.each(:as => :hash).map{|row| [row['answer_id'], row['submitter_name']]}.flatten]
    end
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def qtype
    questioning.qtype
  end

  # gets a set of objects that allow this summary to be compared to others for clustering
  def signature
    [display_type, questioning.option_set, headers]
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