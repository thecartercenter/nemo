# frozen_string_literal: true

module Results
  module Csv
    # Generates CSV from responses in an efficient way. Built to handle millions of Answers.
    class Generator2
      UUID_LENGTH = 36 # This should never change.

      attr_accessor :cur_group_path, :buffer

      def initialize(responses)
        init_cur_group_path
        self.buffer = Buffer.new
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
          result = query
          result.each do |row|
            # If path to group has changed, it's time to dump the CSV row and start a new one!
            buffer.dump_to(csv) if group_path_changed?(row)
            buffer.process_row(row)
          end
          buffer.dump_to(csv)
        end
      end

      def init_cur_group_path
        # -1s ensure it will be changed on first loop.
        self.cur_group_path = group_path_keys.map { |key| [key, -1] }.to_h
      end

      # Checks if the path to the group for the current answer row has changed from the previous row.
      def group_path_changed?(row)
        changed = false
        group_path_keys.each do |key|
          if row[key] != cur_group_path[key]
            changed = true
            cur_group_path[key] = row[key]
          end
        end
        changed
      end

      # Keys/col names from a row that uniquely identify the row's group path.
      def group_path_keys
        @group_path_keys ||= %w[response_id group1_rank group1_item_num]
      end

      def query
        parent_group_name = translation_query("parent_groups.group_name_translations")
        SqlRunner.instance.run("
          SELECT
            responses.id AS response_id,
            forms.name AS form_name,
            users.name AS user_name,
            responses.created_at AS submit_time,
            responses.shortcode AS shortcode,
            #{parent_group_name} AS parent_group_name,
            parent_groups.ancestry_depth AS parent_group_depth,
            CASE parent_groups.ancestry_depth WHEN 0 THEN NULL ELSE parent_groups.rank END AS group1_rank,
            CASE parent_groups.ancestry_depth WHEN 0 THEN NULL ELSE answers.inst_num END AS group1_item_num,
            answers.value AS answer_value,
            CONCAT(
              CASE parent_groups.ancestry_depth WHEN 0 THEN '' ELSE
              CONCAT(#{parent_group_name}, ':') END, questions.code) AS question_code
          FROM responses
            INNER JOIN forms ON responses.form_id = forms.id
            INNER JOIN users ON responses.user_id = users.id
            INNER JOIN answers ON answers.response_id = responses.id
            INNER JOIN form_items qings ON answers.questioning_id = qings.id
            INNER JOIN questions ON qings.question_id = questions.id
            INNER JOIN form_items parent_groups
              ON parent_groups.id = RIGHT(qings.ancestry, #{UUID_LENGTH})::uuid
          ORDER BY responses.created_at, responses.id, group1_rank NULLS FIRST, group1_item_num NULLS FIRST
        ", type_map: false)
      end

      def translation_query(column)
        "COALESCE(
          #{column}->>'#{I18n.locale}',
          #{column}->>'#{I18n.default_locale}',
          #{column}::text)"
      end
    end
  end
end
