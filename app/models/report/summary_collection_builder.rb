class Report::SummaryCollectionBuilder
  attr_reader :questionings, :disagg_qing

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

  # builds a summary collection with the given questionings and disaggregation qing
  # if disagg_qing is nil, no disaggregation will be done
  def initialize(questionings, disagg_qing = nil)
    @questionings = questionings
    @disagg_qing = disagg_qing
  end

  def build
    # split questionings by type
    grouped = {'stat' => [], 'select' => [], 'date' => [], 'raw' => []}
    questionings.each{|qing| grouped[QTYPE_TO_SUMMARY_GROUP[qing.qtype_name]] << qing}

    # generate summary collections for each group
    collections = grouped.keys.map{|g| grouped[g].empty? ? nil : send("collection_for_#{g}_questionings", grouped[g])}.compact.flatten

    # merge to make a single summary collection
    Report::SummaryCollection.merge_all(collections, questionings)
  end

  private

    ####################################################################
    # stat questions
    ####################################################################

    # generates summaries for statistical questions
    # returns a SummaryCollection object
    def collection_for_stat_questionings(stat_qs)
      # do the query
      results_by_disagg_value_and_qing_id = run_stat_query(stat_qs)

      # some supporting arrays
      stats = %w(mean min max)
      qings_by_id = stat_qs.index_by(&:id)

      # build headers
      headers = stats.map{|s| {:name => I18n.t("report/report.standard_form_report.stat_headers.#{s}"), :stat => s.to_sym}}

      # loop over each possible disagg value
      subsets = disagg_values.map do |disagg_value|
        
        # loop over each stat qing
        summaries = stat_qs.map do |qing|

          # get stat values from has we built above
          stat_values = results_by_disagg_value_and_qing_id[[disagg_value.id, qing.id]]

          if stat_values.nil?
            items = []
            null_count = 0
          elsif stat_values['mean'].nil?
            items = []
            null_count = stat_values['null_count']
          else
            # convert stats to appropriate type
            case qing.qtype_name
            when 'integer'
              stat_values['mean'] = stat_values['mean'].to_f
              %w(max min).each{|s| stat_values[s] = stat_values[s].to_i}
            when 'decimal'
              stats.each{|s| stat_values[s] = stat_values[s].to_f}
            when 'time'
              stats.each{|s| stat_values[s] = I18n.l(Time.parse(stat_values[s]), :format => :time_only)}
            when 'datetime'
              stats.each{|s| stat_values[s] = I18n.l(Time.zone.parse(stat_values[s] + ' UTC'))}
            end

            # build items
            items = stats.map{|stat| Report::SummaryItem.new(:qtype_name => qing.qtype_name, :stat => stat_values[stat])}
            null_count = stat_values['null_count']
          end

          # build summary and store in hash
          Report::QuestionSummary.new(:questioning => qing, :display_type => :structured, 
            :headers => headers, :items => items, :null_count => null_count)
        end

        # build blank summaries for missing qings
        already_summarized = summaries.map(&:questioning)
        summaries += (stat_qs - already_summarized).map do |qing|
          Report::QuestionSummary.new(:questioning => qing, :display_type => :structured, :headers => headers, :items => [], :null_count => 0)
        end

        # make a subset for the current disagg_value for this set of summaries
        Report::SummarySubset.new(:disagg_value => disagg_value, :summaries => summaries)
      end

      Report::SummaryCollection.new(:subsets => subsets, :questionings => stat_qs)
    end

    # builds and executes a query for summary info for stat questions
    # returns a hash of the form {[disagg_value, qing_id] => {'mean' => x.x, 'min' => x, 'max' => x}, ...}
    def run_stat_query(stat_qs)
      qing_ids = stat_qs.map(&:id).join(',')

      query = <<-eos
        SELECT #{disagg_select_expr} qing.id AS qing_id, q.qtype_name AS qtype_name, 
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
          #{disagg_join_clause}
        WHERE q.qtype_name in ('integer', 'decimal', 'time', 'datetime') 
        GROUP BY #{disagg_group_by_expr} qing.id, q.qtype_name
      eos
      res = ActiveRecord::Base.connection.execute(query)

      # build hash
      hash = ActiveSupport::OrderedHash[]
      res.each(:as => :hash) do |row|
        hash[[row['disagg_value'], row['qing_id']]] = row
      end
      hash
    end

    ####################################################################
    # select questions
    ####################################################################

    def collection_for_select_questionings(select_qs)
      qing_ids = select_qs.map(&:id).join(',')

      # get tallies of answers
      tallies = get_select_question_tallies(qing_ids)

      # get tallies of non_null answers for each select multiple question
      sel_mult_non_null_tallies = get_sel_mult_non_null_tallies(qing_ids)

      # loop over each possible disagg_value to generate subsets
      subsets = disagg_values.map do |disagg_value|

        # loop over each questioning to generate summaries
        summaries = select_qs.map do |qing|
          
          # build headers
          headers = qing.options.map{|option| {:name => option.name, :option => option}}

          # build tallies, keeping a running sum of non-null answers
          non_null_count = 0
          items = qing.options.map do |o|
            count = tallies[[disagg_value.id, qing.id, o.id]] || 0
            non_null_count += count
            Report::SummaryItem.new(:count => count)
          end

          # if this is a sel mult question, the non_null_count we summed reflects the total number of non_null choices, not answers
          # but to compute percentages, we are interested in the non-null answer value, so get it from the hash we built above
          non_null_count = sel_mult_non_null_tallies[[disagg_value.id, qing.id]] || 0 if qing.qtype_name == 'select_multiple'

          # compute percentages
          items.each do |item|
            item.pct = non_null_count == 0 ? 0 : item.count.to_f / non_null_count * 100
          end

          # null count should be zero for sel multiple b/c no selection can be a valid answer
          null_count = qing.qtype_name == 'select_one' ? tallies[[disagg_value.id, qing.id, nil]] : 0

          # build summary
          Report::QuestionSummary.new(:questioning => qing, :display_type => :structured, :overall_header => qing.option_set.name, 
            :headers => headers, :items => items, :null_count => null_count)
        end

        # make a subset for the current disagg_value for this set of summaries
        Report::SummarySubset.new(:disagg_value => disagg_value, :summaries => summaries)
      end

      Report::SummaryCollection.new(:subsets => subsets, :questionings => select_qs)
    end

    # gets a hash of form [disagg_value, qing_id, option_id] => tally for the given select questioning_ids
    def get_select_question_tallies(qing_ids)

      # build and run queries for select_one and _multiple
      query = <<-eos
        SELECT #{disagg_select_expr} qings.id AS qing_id, a.option_id AS option_id, COUNT(a.id) AS answer_count 
        FROM questionings qings 
          INNER JOIN questions q ON qings.question_id = q.id 
          LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
          #{disagg_join_clause}
          WHERE q.qtype_name IN ('select_one', 'select_multiple')
            AND qings.id IN (#{qing_ids})
          GROUP BY #{disagg_group_by_expr} qings.id, a.option_id
      eos
      sel_one_res = ActiveRecord::Base.connection.execute(query)
      
      query = <<-eos
        SELECT #{disagg_select_expr} qings.id AS qing_id, c.option_id AS option_id, COUNT(c.id) AS choice_count 
        FROM questionings qings 
          INNER JOIN questions q ON qings.question_id = q.id 
          LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
          LEFT OUTER JOIN choices c ON a.id = c.answer_id
          #{disagg_join_clause}
          WHERE q.qtype_name = 'select_multiple'
            AND qings.id IN (#{qing_ids})
          GROUP BY #{disagg_group_by_expr} qings.id, c.option_id
      eos
      sel_mult_res = ActiveRecord::Base.connection.execute(query)

      # read tallies into hashes
      tallies = {}
      sel_one_res.each(:as => :hash).each do |row|
        tallies[[row['disagg_value'], row['qing_id'], row['option_id']]] = row['answer_count']
      end
      sel_mult_res.each(:as => :hash).each do |row|
        tallies[[row['disagg_value'], row['qing_id'], row['option_id']]] = row['choice_count']
      end
      tallies
    end

    # gets tallies of non-null answers for the given select-multiple qing_ids
    # useful in computing percentages
    def get_sel_mult_non_null_tallies(qing_ids)
      # get the non-null answer counts for sel mult questions
      query = <<-eos
        SELECT #{disagg_select_expr} qings.id AS qing_id, COUNT(DISTINCT a.id) AS non_null_answer_count
        FROM questionings qings 
          INNER JOIN questions q ON qings.question_id = q.id 
          LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
          LEFT OUTER JOIN choices c ON a.id = c.answer_id
          #{disagg_join_clause}
          WHERE q.qtype_name = 'select_multiple'
            AND qings.id IN (#{qing_ids})
            AND c.id IS NOT NULL
          GROUP BY #{disagg_group_by_expr} qings.id
      eos
      res = ActiveRecord::Base.connection.execute(query)

      # read non-null answer counts into hash
      tallies = {}
      res.each(:as => :hash).each do |row|
        tallies[[row['disagg_value'], row['qing_id']]] = row['non_null_answer_count']
      end
      tallies
    end

    ####################################################################
    # date questions
    ####################################################################

    def collection_for_date_questionings(date_qs)
      # get tallies for each qing and date
      tallies = get_date_question_tallies(date_qs)

      # loop over each possible disagg_value to generate subsets
      subsets = disagg_values.map do |disagg_value|

        # loop over each questioning to generate summaries
        summaries = date_qs.map do |qing|

          # get tallies for this disagg_value and qing
          cur_tallies = tallies[[disagg_value.id, qing.id]]

          # build headers from tally keys (already sorted)
          headers = (cur_tallies ? cur_tallies.keys.reject(&:nil?) : []).map{|date| {:name => I18n.l(date), :date => date}}
          
          # build tallies, keeping a running sum
          non_null_count = 0
          items = headers.map do |h|
            count = cur_tallies[h[:date]] || 0
            non_null_count += count
            Report::SummaryItem.new(:count => count)
          end

          # compute percentages
          items.each do |item|
            item.pct = non_null_count == 0 ? 0 : item.count.to_f / non_null_count * 100
          end

          # get null count from tallies
          null_count = cur_tallies[nil] || 0

          # build summary
          Report::QuestionSummary.new(:questioning => qing, :display_type => :structured, 
            :overall_header => I18n.t('report/report.standard_form_report.overall_headers.dates'),
            :headers => headers, :items => items, :null_count => null_count)
        end

        # make a subset for the current disagg_value for this set of summaries
        Report::SummarySubset.new(:disagg_value => disagg_value, :summaries => summaries)
      end

      Report::SummaryCollection.new(:subsets => subsets, :questionings => date_qs)
    end

    # gets tallies of dates and answers for each of the given questionings
    def get_date_question_tallies(date_qs)
      qing_ids = date_qs.map(&:id).join(',')

      # build and run query
      query = <<-eos
        SELECT #{disagg_select_expr} qings.id AS qing_id, a.date_value AS date, COUNT(a.id) AS answer_count 
        FROM questionings qings
          INNER JOIN questions q ON qings.question_id = q.id 
          LEFT OUTER JOIN answers a ON qings.id = a.questioning_id
          #{disagg_join_clause}
          WHERE q.qtype_name = 'date'
            AND qings.id IN (#{qing_ids})
          GROUP BY #{disagg_group_by_expr} qings.id, a.date_value
          ORDER BY disagg_value, qing_id, date
      eos
      res = ActiveRecord::Base.connection.execute(query)

      # read into tallies, preserving sorted date order
      tallies = {}
      res.each(:as => :hash).each do |row|
        tallies[[row['disagg_value'], row['qing_id']]] ||= ActiveSupport::OrderedHash[]
        tallies[[row['disagg_value'], row['qing_id']]][row['date']] = row['answer_count']
      end
      tallies
    end

    ####################################################################
    # date questions
    ####################################################################

    def collection_for_raw_questionings(raw_qs)
      qing_ids = raw_qs.map(&:id)

      # do answer query
      answers = Answer.where(:questioning_id => qing_ids).order('created_at')

      # get submitter names for long text q's
      submitter_names = get_submiter_names(raw_qs)

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
      raw_qs.map do |qing|

        # get items from hash
        items = items_by_qing_id[qing.id] || []

        # display type is only 'full_width' if long text
        display_type = qing.qtype_name == 'long_text' ? :full_width : :flow

        # null count from hash also
        null_count = null_counts_by_qing_id[qing.id] || 0

        # build summary
        Report::QuestionSummary.new(:questioning => qing, :display_type => display_type, :overall_header => I18n.t('report/report.standard_form_report.overall_headers.responses'),
          :headers => [], :items => items, :null_count => null_count)
      end
    end

    # gets a hash of answer_id to submitter names for each long_text answer to questionings in the given array
    def get_submiter_names(raw_qs)
      # get ids of long_text q's from the given array
      # (should be eager loaded with Question to avoid n+1)
      long_qing_ids = raw_qs.find_all{|q| q.qtype_name == 'long_text'}.map(&:id)

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

    # returns all possible disagg_values
    def disagg_values
      disagg_qing.options
    end

    # returns a fully qualified column reference for the disaggregation value
    def disagg_column
      'disagg_ans.option_id'
    end

    # gets the extra sql select expression that needs to be added to each query if we're disaggregating
    def disagg_select_expr
      return '' if disagg_qing.nil?
      "#{disagg_column} AS disagg_value,"
    end

    # gets the extra join clause that needs to be added to each query if we're disaggregating
    def disagg_join_clause
      return '' if disagg_qing.nil?
      <<-eos
        INNER JOIN responses r ON a.response_id = r.id
        LEFT OUTER JOIN answers disagg_ans ON r.id = disagg_ans.response_id AND disagg_ans.questioning_id = #{disagg_qing.id}
      eos
    end

    # gets the extra group by expression that needs to be added to each query if we're disaggregating
    def disagg_group_by_expr
      return '' if disagg_qing.nil?
      "#{disagg_column},"
    end
end