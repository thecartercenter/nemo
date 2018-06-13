class Report::SummaryCollectionBuilder
  attr_reader :questionings, :disagg_qing

  # hash for converting qtypes to groups (stat, select, date, raw) used for generating summaries
  QTYPE_TO_SUMMARY_GROUP = {
    'integer' => 'stat',
    'counter' => 'stat',
    'decimal' => 'stat',
    'time' => 'stat',
    'datetime' => 'stat',
    'select_one' => 'select',
    'select_multiple' => 'select',
    'date' => 'date',
    'text' => 'raw',
    'long_text' => 'raw'
  }

  # Quantity of raw answers that should be shown on report for each question
  RAW_ANSWER_LIMIT = 100

  # builds a summary collection with the given questionings and disaggregation qing
  # if disagg_qing is nil, no disaggregation will be done
  # options[:restrict_to_user] - (optional) If specified, only Responses for the given user will be included in the results.
  def initialize(questionings, disagg_qing, options = {})

    @disagg_qing = disagg_qing
    @options = options

    # should not include disagg_qing in summaries
    # we use reject so that we don't mess up the originally passed array
    @questionings = questionings.reject{|qing| qing == disagg_qing}
  end

  def build
    # split questionings by type
    grouped = {'stat' => [], 'select' => [], 'date' => [], 'raw' => []}
    questionings.each{|qing| grouped[QTYPE_TO_SUMMARY_GROUP[qing.qtype_name]] << qing}

    # generate summary collections for each group
    collections = grouped.keys.map{|g| grouped[g].empty? ? nil : send("collection_for_#{g}_questionings", grouped[g])}.compact.flatten

    # merge to make a single summary collection
    collection = Report::SummaryCollection.merge_all(collections, questionings)

    # remove the null subset if empty
    collection.remove_null_subset_if_empty!

    collection
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
          stat_values = results_by_disagg_value_and_qing_id[[disagg_value, qing.id]]

          if stat_values.nil?
            items = []
            null_count = 0
          elsif stat_values['mean'].nil?
            items = []
            null_count = stat_values['null_count']
          else
            # convert stats to appropriate type
            case qing.qtype_name
            when 'integer', 'counter'
              stat_values['mean'] = stat_values['mean'].to_f
              %w(max min).each{|s| stat_values[s] = stat_values[s].to_i}
            when 'decimal'
              stats.each{|s| stat_values[s] = stat_values[s].to_f}
            when 'time'
              stats.each{|s| stat_values[s] = I18n.l(Time.parse(stat_values[s]), :format => :time_only)}
            when 'datetime'
              # Datetime values are in UTC so we convert them to string and then parse them into our zone.
              # Sometimes the zone shown in to_s is something other than UTC but it really is UTC so we
              # strip it out before parsing.
              stats.each{|s| stat_values[s] = I18n.l(Time.zone.parse(stat_values[s].strftime("%Y-%m-%d %H:%M:%S UTC")))}
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
      qing_ids = stat_qs.map(&:id)
      queries = []
      queries << <<-SQL
        SELECT #{disagg_select_expr} qing.id AS qing_id,
          SUM(CASE WHEN a.value IS NULL OR a.value = '' THEN 1 ELSE 0 END) AS null_count,
          CAST(AVG(CAST(a.value AS INTEGER)) AS TEXT) AS mean,
          CAST(MIN(CAST(a.value AS INTEGER)) AS TEXT) AS min,
          CAST(MAX(CAST(a.value AS INTEGER)) AS TEXT) AS max
        FROM answers a INNER JOIN form_items qing
            ON qing.deleted_at IS NULL AND qing.type='Questioning'
              AND a.questioning_id = qing.id AND qing.id IN (?)
          INNER JOIN questions q ON q.id = qing.question_id AND q.deleted_at IS NULL
          #{disagg_join_clause}
          #{current_user_join_clause}
        WHERE a.deleted_at IS NULL AND a.type = 'Answer' AND (q.qtype_name = 'integer' OR q.qtype_name = 'counter')
        GROUP BY #{disagg_group_by_expr} qing.id
      SQL

      queries << <<-SQL
        SELECT #{disagg_select_expr} qing.id AS qing_id,
          SUM(CASE WHEN a.value IS NULL OR a.value = '' THEN 1 ELSE 0 END) AS null_count,
          CAST(AVG(CAST(a.value AS DECIMAL(20,6))) AS TEXT) AS mean,
          CAST(MIN(CAST(a.value AS DECIMAL(20,6))) AS TEXT) AS min,
          CAST(MAX(CAST(a.value AS DECIMAL(20,6))) AS TEXT) AS max
        FROM answers a INNER JOIN form_items qing
          ON qing.deleted_at IS NULL AND qing.type='Questioning'
            AND a.questioning_id = qing.id AND qing.id IN (?)
          INNER JOIN questions q ON q.id = qing.question_id AND q.deleted_at IS NULL
          #{disagg_join_clause}
          #{current_user_join_clause}
        WHERE a.deleted_at IS NULL AND a.type = 'Answer' AND q.qtype_name = 'decimal'
        GROUP BY #{disagg_group_by_expr} qing.id
      SQL

      time_extracts = "EXTRACT(hour from a.time_value)*60*60 + " \
        "EXTRACT(minutes FROM a.time_value)*60 + " \
        "EXTRACT(seconds FROM a.time_value)"
      queries << <<-SQL
        SELECT #{disagg_select_expr} qing.id AS qing_id,
          SUM(CASE WHEN a.time_value IS NULL THEN 1 ELSE 0 END) AS null_count,
          CAST(TO_CHAR((AVG(#{time_extracts}) || ' seconds')::interval, 'HH24:MM:SS') AS TEXT) AS mean,
          CAST(MIN(a.time_value) AS TEXT) AS min,
          CAST(MAX(a.time_value) AS TEXT) AS max
        FROM answers a INNER JOIN form_items qing ON qing.deleted_at IS NULL AND qing.type='Questioning'
          AND a.questioning_id = qing.id AND qing.id IN (?)
          INNER JOIN questions q ON q.id = qing.question_id AND q.deleted_at IS NULL
          #{disagg_join_clause}
          #{current_user_join_clause}
        WHERE a.deleted_at IS NULL AND a.type = 'Answer' AND q.qtype_name = 'time'
        GROUP BY #{disagg_group_by_expr} qing.id
      SQL

      queries << <<-SQL
        SELECT #{disagg_select_expr} qing.id AS qing_id,
          SUM(CASE WHEN a.datetime_value IS NULL THEN 1 ELSE 0 END) AS null_count,
          to_timestamp(AVG(extract(epoch FROM a.datetime_value))) AS mean,
          MIN(a.datetime_value) AS min,
          MAX(a.datetime_value) AS max
        FROM answers a INNER JOIN form_items qing ON qing.deleted_at IS NULL AND qing.type='Questioning'
          AND a.questioning_id = qing.id AND qing.id IN (?)
          INNER JOIN questions q ON q.deleted_at IS NULL AND q.id = qing.question_id
          #{disagg_join_clause}
          #{current_user_join_clause}
        WHERE a.deleted_at IS NULL AND a.type = 'Answer' AND q.qtype_name = 'datetime'
        GROUP BY #{disagg_group_by_expr} qing.id
      SQL

      # Run queries and build hash
      ActiveSupport::OrderedHash.new.tap do |hash|
        queries.each do |query|
          res = sql_runner.run(query, qing_ids)

          res.each do |row|
            # Get the object from the disagg value as returned from the db
            row['disagg_value'] = disagg_value_db_to_obj[row['disagg_value']]
            hash[[row['disagg_value'], row['qing_id']]] = row
          end
        end
      end
    end

    ####################################################################
    # select questions
    ####################################################################

    def collection_for_select_questionings(select_qs)
      qing_ids = select_qs.map(&:id)

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
            count = tallies[[disagg_value, qing.id, o.id]] || 0
            non_null_count += count
            Report::SummaryItem.new(:count => count)
          end

          # if this is a sel mult question, the non_null_count we summed reflects the total number of non_null choices, not answers
          # but to compute percentages, we are interested in the non-null answer value, so get it from the hash we built above
          non_null_count = sel_mult_non_null_tallies[[disagg_value, qing.id]] || 0 if qing.qtype_name == 'select_multiple'

          # compute percentages
          items.each do |item|
            item.pct = non_null_count == 0 ? 0 : item.count.to_f / non_null_count * 100
          end

          # null count should be zero for sel multiple b/c no selection can be a valid answer
          null_count = qing.qtype_name == 'select_one' ? tallies[[disagg_value, qing.id, nil]] : 0

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
      query = <<-SQL
        SELECT #{disagg_select_expr} qings.id AS qing_id, a.option_id AS option_id, COUNT(a.id) AS answer_count
        FROM form_items qings
          INNER JOIN questions q ON qings.question_id = q.id AND q.deleted_at IS NULL
          LEFT OUTER JOIN answers a
            ON qings.id = a.questioning_id AND a.deleted_at IS NULL AND a.type = 'Answer'
          #{disagg_join_clause}
          #{current_user_join_clause}
          WHERE qings.deleted_at IS NULL
            AND q.qtype_name = 'select_one'
            AND qings.type = 'Questioning'
            AND qings.id IN (?)
            AND (a.rank IS NULL OR a.rank = 1)
          GROUP BY #{disagg_group_by_expr} qings.id, a.option_id
      SQL

      sel_one_res = sql_runner.run(query, qing_ids)

      query = <<-SQL
        SELECT #{disagg_select_expr} qings.id AS qing_id, c.option_id AS option_id, COUNT(c.id) AS choice_count
        FROM form_items qings
          INNER JOIN questions q ON qings.question_id = q.id AND q.deleted_at IS NULL
          LEFT OUTER JOIN answers a
            ON qings.id = a.questioning_id AND a.deleted_at IS NULL AND a.type = 'Answer'
          LEFT OUTER JOIN choices c ON a.id = c.answer_id AND c.deleted_at IS NULL
          #{disagg_join_clause}
          #{current_user_join_clause}
          WHERE qings.deleted_at IS NULL
            AND q.qtype_name = 'select_multiple'
            AND qings.type = 'Questioning'
            AND qings.id IN (?)
          GROUP BY #{disagg_group_by_expr} qings.id, c.option_id
      SQL

      sel_mult_res = sql_runner.run(query, qing_ids)

      # read tallies into hashes
      tallies = {}
      sel_one_res.each do |row|
        # get the object from the disagg value as returned from the db
        row['disagg_value'] = disagg_value_db_to_obj[row['disagg_value']]

        tallies[[row['disagg_value'], row['qing_id'], row['option_id']]] = row['answer_count']
      end
      sel_mult_res.each do |row|
        # get the object from the disagg value as returned from the db
        row['disagg_value'] = disagg_value_db_to_obj[row['disagg_value']]

        tallies[[row['disagg_value'], row['qing_id'], row['option_id']]] = row['choice_count']
      end
      tallies
    end

    # gets tallies of non-null answers for the given select-multiple qing_ids
    # useful in computing percentages
    def get_sel_mult_non_null_tallies(qing_ids)
      # get the non-null answer counts for sel mult questions
      query = <<-SQL
        SELECT #{disagg_select_expr} qings.id AS qing_id, COUNT(DISTINCT a.id) AS non_null_answer_count
        FROM form_items qings
          INNER JOIN questions q ON qings.question_id = q.id AND q.deleted_at IS NULL
          LEFT OUTER JOIN answers a
            ON qings.id = a.questioning_id AND a.deleted_at IS NULL AND a.type = 'Answer'
          LEFT OUTER JOIN choices c ON a.id = c.answer_id AND c.deleted_at IS NULL
          #{disagg_join_clause}
          #{current_user_join_clause}
          WHERE qings.deleted_at IS NULL
            AND q.qtype_name = 'select_multiple'
            AND qings.type = 'Questioning'
            AND qings.id IN (?)
            AND c.id IS NOT NULL
          GROUP BY #{disagg_group_by_expr} qings.id
      SQL

      res = sql_runner.run(query, qing_ids)

      # read non-null answer counts into hash
      tallies = {}
      res.each do |row|
        # get the object from the disagg value as returned from the db
        row['disagg_value'] = disagg_value_db_to_obj[row['disagg_value']]

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

          # get tallies for this disagg_value and qing (could be nil)
          cur_tallies = tallies[[disagg_value, qing.id]]

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
          null_count = (cur_tallies || {})[nil] || 0

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
      qing_ids = date_qs.map(&:id)

      # build and run query
      query = <<-SQL
        SELECT #{disagg_select_expr} qings.id AS qing_id, a.date_value AS date, COUNT(a.id) AS answer_count
        FROM form_items qings
          INNER JOIN questions q ON qings.question_id = q.id AND q.deleted_at IS NULL
          LEFT OUTER JOIN answers a
            ON qings.id = a.questioning_id AND a.deleted_at IS NULL AND a.type = 'Answer'
          #{disagg_join_clause}
          #{current_user_join_clause}
          WHERE qings.deleted_at IS NULL
            AND q.qtype_name = 'date'
            AND qings.id IN (?)
            AND qings.type = 'Questioning'
          GROUP BY #{disagg_group_by_expr} qings.id, a.date_value
          ORDER BY disagg_value, qing_id, date
      SQL

      res = sql_runner.run(query, qing_ids)

      # read into tallies, preserving sorted date order
      tallies = {}
      res.each do |row|
        # get the object from the disagg value as returned from the db
        row['disagg_value'] = disagg_value_db_to_obj[row['disagg_value']]

        tallies[[row['disagg_value'], row['qing_id']]] ||= ActiveSupport::OrderedHash[]
        tallies[[row['disagg_value'], row['qing_id']]][row['date']] = row['answer_count']
      end
      tallies
    end

    ####################################################################
    # raw questions
    ####################################################################

    def collection_for_raw_questionings(raw_qs)
      # do answer query
      res = run_raw_answer_query(raw_qs)

      # get submitter names for long text q's
      submitter_names = get_submitter_names(raw_qs)

      # build summary *items* and index by disagg_value and qing_id
      # also keep null counts
      items_hash = {}
      null_counts_hash = {}
      res.each do |row|
        # get the object from the disagg value as returned from the db
        row['disagg_value'] = disagg_value_db_to_obj[row['disagg_value']]

        # ensure both initialized
        items_hash[[row['disagg_value'], row['qing_id']]] ||= []
        null_counts_hash[[row['disagg_value'], row['qing_id']]] ||= 0

        # increment null count or add item
        if row['value'].blank?
          null_counts_hash[[row['disagg_value'], row['qing_id']]] += 1
        else
          item = Report::SummaryItem.new(:text => row['value'])

          # add response info for long text q's
          if name = submitter_names[row['id']]
            item.response_id = row['response_id']
            item.created_at = I18n.l(row['created_at'])
            item.submitter_name = name
          end

          items_hash[[row['disagg_value'], row['qing_id']]] << item
        end
      end

      # build subsets
      subsets = disagg_values.map do |disagg_value|

        # build summaries for this disagg_value
        summaries = raw_qs.map do |qing|

          # get items from hash
          items = items_hash[[disagg_value, qing.id]] || []

          # display type is only 'full_width' if long text
          display_type = qing.qtype_name == 'long_text' ? :full_width : :flow

          # null count from hash also
          null_count = null_counts_hash[[disagg_value, qing.id]] || 0

          # build summary (headers are blank b/c there is only one column so header is always the same ('responses'))
          Report::QuestionSummary.new(:questioning => qing, :display_type => display_type,
            :overall_header => I18n.t('report/report.standard_form_report.overall_headers.responses'),
            :headers => [], :items => items, :null_count => null_count)
        end

        # make a subset for the current disagg_value for this set of summaries
        Report::SummarySubset.new(:disagg_value => disagg_value, :summaries => summaries)
      end

      Report::SummaryCollection.new(:subsets => subsets, :questionings => raw_qs)
    end

    # runs a query to get each answer for the given qings
    # returns a mysql result
    def run_raw_answer_query(raw_qs)
      qing_ids = raw_qs.map(&:id)

      # build and run query
      query = <<-SQL
        SELECT #{disagg_select_expr} a.id AS id, a.questioning_id AS qing_id, a.value AS value,
          a.response_id AS response_id, a.created_at AS created_at
        FROM answers a
          #{disagg_join_clause}
          #{current_user_join_clause}
          WHERE a.deleted_at IS NULL AND a.type = 'Answer' AND a.questioning_id IN (?)
          ORDER BY disagg_value, a.created_at
          LIMIT #{RAW_ANSWER_LIMIT}
      SQL

      sql_runner.run(query, qing_ids)
    end

    # gets a hash of answer_id to submitter names for each long_text answer to questionings in the given array
    def get_submitter_names(raw_qs)
      # get ids of long_text q's from the given array
      # (should be eager loaded with Question to avoid n+1)
      long_qing_ids = raw_qs.find_all{|q| q.qtype_name == 'long_text'}.map(&:id)

      # get submitter info for long text responses and store in hash
      if long_qing_ids.empty?
        {}
      else
        query = <<-SQL
          SELECT a.id AS answer_id, u.name AS submitter_name
          FROM answers a
            INNER JOIN responses r ON r.deleted_at IS NULL AND a.response_id = r.id
            INNER JOIN users u ON u.deleted_at IS NULL AND r.user_id = u.id
          WHERE a.deleted_at IS NULL AND a.type = 'Answer' AND a.questioning_id IN (?)
        SQL

        res = sql_runner.run(query, long_qing_ids)

        res.map{|row| [row['answer_id'], row['submitter_name']]}.to_h
      end
    end

    # returns all possible disagg_values
    def disagg_values
      # if there is no disagg_qing, this is just the symbol :all
      if disagg_qing.nil?
        [:all]

      # otherwise we return each of the options for the question, plus nil,
      # since we need to include a subset for responses with no answer to the disagg_qing
      else
        disagg_qing.options + [nil]
      end
    end

    # returns a hash of disagg_value as returned from the db (e.g. 123) to the objects we want to use (e.g. Option)
    def disagg_value_db_to_obj
      if disagg_qing.nil?
        {'all' => :all}
      else
        @disagg_value_db_to_obj ||= Hash[*disagg_qing.options.map{|o| [o.id, o]}.flatten]
      end
    end

    # returns a fully qualified column reference for the disaggregation value
    def disagg_column
      if disagg_qing.nil?
        "CAST('all' AS TEXT)"
      else
        'disagg_ans.option_id'
      end
    end

    # gets the extra sql select expression that needs to be added to each query if we're disaggregating
    def disagg_select_expr
      "#{disagg_column} AS disagg_value,"
    end

    # gets the extra join clause that needs to be added to each query if we're disaggregating
    def disagg_join_clause
      return '' if disagg_qing.nil?
      <<-SQL
        INNER JOIN responses r ON r.deleted_at IS NULL AND a.response_id = r.id
        LEFT OUTER JOIN answers disagg_ans ON disagg_ans.deleted_at IS NULL
          AND r.id = disagg_ans.response_id AND disagg_ans.questioning_id = '#{disagg_qing.id}'
      SQL
    end

    # restrict query to responses enumerator has access to. admins and coordinators have access to all responses.
    def current_user_join_clause
      return '' unless @options && @options[:restrict_to_user]
      <<-SQL
        INNER JOIN responses res ON res.deleted_at IS NULL
          AND a.response_id = res.id AND res.user_id = '#{@options[:restrict_to_user].id}'
      SQL
    end

    # gets the extra group by expression that needs to be added to each query if we're disaggregating
    def disagg_group_by_expr
      return '' if disagg_qing.nil?
      "#{disagg_column},"
    end

    def sql_runner
      SqlRunner.instance
    end
end
