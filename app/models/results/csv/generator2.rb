# frozen_string_literal: true

module Results
  module Csv
    # Generates CSV from responses in an efficient way. Built to handle millions of Answers.
    class Generator2
      UUID_LENGTH = 36 # This should never change.

      attr_accessor :buffer, :answer_processor

      def initialize(responses)
        self.buffer = Buffer.new(
          max_depth: 1,
          common_headers: %w[response_id form_name user_name submit_time shortcode]
        )
        self.answer_processor = AnswerProcessor.new(buffer)
      end

      # Runs the queries and returns the CSV as a string.
      def to_s
        csv_body.prepend(csv_headers)
      end

      private

      def csv_headers
        CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
          csv << buffer.headers
        end
      end

      def csv_body
        CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
          buffer.csv = csv
          query.each do |row|
            buffer.process_row(row)
            answer_processor.process(row)
          end
          buffer.finish
        end
      end

      def query
        set_db_timezone do
          # The type map is very slow and we don't need it since we're outputting strings.
          SqlRunner.instance.run("#{select} #{from} #{order}", use_type_map: false)
        end
      end

      def select
        parent_group_name = translation_query("parent_groups.group_name_translations")
        answer_option_name = translation_query("answer_options.name_translations")
        choice_option_name = translation_query("choice_options.name_translations")
        <<~SQL
          SELECT
            responses.id AS response_id,
            forms.name AS form_name,
            users.name AS user_name,
            responses.created_at AT TIME ZONE 'UTC' AS submit_time,
            responses.shortcode AS shortcode,
            #{parent_group_name} AS parent_group_name,
            parent_groups.ancestry_depth AS parent_group_depth,
            CASE parent_groups.ancestry_depth WHEN 0 THEN NULL ELSE parent_groups.rank END AS group1_rank,
            CASE parent_groups.ancestry_depth WHEN 0 THEN NULL ELSE answers.inst_num END AS group1_item_num,
            answers.value AS value,
            answers.time_value,
            answers.date_value,
            answers.datetime_value,
            #{answer_option_name} AS answer_option_name,
            #{choice_option_name} AS choice_option_name,
            questions.code AS question_code
        SQL
      end

      def from
        <<~SQL
          FROM responses
            INNER JOIN forms ON responses.form_id = forms.id
            INNER JOIN users ON responses.user_id = users.id
            INNER JOIN answers ON answers.response_id = responses.id
            INNER JOIN form_items qings ON answers.questioning_id = qings.id
            INNER JOIN questions ON qings.question_id = questions.id
            INNER JOIN form_items parent_groups
              ON parent_groups.id = RIGHT(qings.ancestry, #{UUID_LENGTH})::uuid
            LEFT OUTER JOIN options answer_options ON answer_options.id = answers.option_id
            LEFT OUTER JOIN choices ON choices.answer_id = answers.id
            LEFT OUTER JOIN options choice_options ON choices.option_id = choice_options.id
        SQL
      end

      def order
        <<~SQL
          ORDER BY
            responses.created_at,
            responses.id,
            group1_rank NULLS FIRST,
            group1_item_num NULLS FIRST,
            qings.rank
        SQL
      end

      def translation_query(column)
        tries = ["#{column}->>'#{I18n.locale}'", "#{column}->>'#{I18n.default_locale}'", "#{column}::text"]
        "COALESCE(#{tries.uniq.join(', ')})"
      end

      # Sets the DB's timezone to the current one so that the response times are shown with a timezone
      # offset. This is faster than doing it in Ruby.
      def set_db_timezone
        SqlRunner.instance.run("SET SESSION TIME ZONE INTERVAL '#{Time.zone.formatted_offset}'")
        yield
      ensure
        # The DB should generally be in UTC zone. Rails handles conversions internally.
        SqlRunner.instance.run("SET SESSION TIME ZONE 'UTC'")
      end
    end
  end
end
