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
        option_level_name = translation_query("option_sets.level_names", arr_index: "answers.rank - 1")
        <<~SQL
          SELECT
            responses.id AS response_id,
            forms.name AS form_name,
            users.name AS user_name,
            responses.created_at AT TIME ZONE 'UTC' AS submit_time,
            responses.shortcode AS shortcode,
            #{parent_group_name} AS parent_group_name,
            (SELECT ARRAY_AGG(anc.type || anc.new_rank ORDER BY ah.generations DESC)
              FROM answer_hierarchies ah INNER JOIN answers anc ON ah.ancestor_id = anc.id
              WHERE answers.id = ah.descendant_id) AS ancestry,
            answers.value AS value,
            answers.time_value,
            answers.date_value,
            answers.datetime_value AT TIME ZONE 'UTC' AS datetime_value,
            answers.latitude,
            answers.longitude,
            answers.altitude,
            answers.accuracy,
            #{answer_option_name} AS answer_option_name,
            answer_options.value AS answer_option_value,
            #{choice_option_name} AS choice_option_name,
            questions.code AS question_code,
            #{option_level_name} AS option_level_name
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
            INNER JOIN answer_hierarchies anc1s ON answers.id = anc1s.descendant_id AND anc1s.generations = 1
            INNER JOIN answers parent1s ON anc1s.ancestor_id = parent1s.id
            INNER JOIN form_items parent_groups ON parent_groups.id = parent1s.questioning_id
            LEFT OUTER JOIN answer_hierarchies anc2s ON answers.id = anc2s.descendant_id AND anc2s.generations = 1
            LEFT OUTER JOIN answers parent2s ON anc2s.ancestor_id = parent2s.id
            LEFT OUTER JOIN option_sets ON questions.option_set_id = option_sets.id
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
            (SELECT ARRAY_AGG(anc.new_rank ORDER BY ah.generations DESC)
              FROM answer_hierarchies ah INNER JOIN answers anc ON ah.ancestor_id = anc.id
              WHERE answers.id = ah.descendant_id),
            choice_option_name
        SQL
      end
    end
  end
end
