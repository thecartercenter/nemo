# frozen_string_literal: true

module Results
  module Csv
    # The query to get all the answer data.
    class AnswerQuery < Query
      protected

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

      def where
        ""
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
    end
  end
end
