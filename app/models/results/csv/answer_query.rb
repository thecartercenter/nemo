# frozen_string_literal: true

module Results
  module CSV
    # The query to get all the answer data.
    class AnswerQuery < Query
      protected

      def select
        answer_option_name = translation_query("answer_options.name_translations")
        choice_option_name = translation_query("choice_options.name_translations")
        option_level_name = translation_query("option_sets.level_names",
          arr_index: "CASE WHEN parents.type = 'AnswerSet' THEN answers.new_rank ELSE 0 END")
        <<~SQL.squish
          SELECT
            responses.id AS response_id,
            forms.name AS form_name,
            users.name AS user_name,
            responses.created_at AT TIME ZONE 'UTC' AS submit_time,
            responses.shortcode AS shortcode,
            responses.reviewed AS reviewed,
            (SELECT
              ARRAY_AGG(anc.type || ':' || anc.new_rank || ':' || anc.questioning_id
                ORDER BY ah.generations DESC)
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
            choice_options.value AS choice_option_value,
            questions.code AS question_code,
            questions.qtype_name AS qtype_name,
            #{option_level_name} AS option_level_name
        SQL
      end

      def from
        <<~SQL.squish
          FROM responses
            INNER JOIN forms ON responses.form_id = forms.id
            INNER JOIN users ON responses.user_id = users.id
            INNER JOIN answers ON answers.response_id = responses.id
            INNER JOIN answers parents ON parents.id = answers.parent_id
            INNER JOIN form_items qings ON answers.questioning_id = qings.id
            INNER JOIN questions ON qings.question_id = questions.id
            LEFT OUTER JOIN option_sets ON questions.option_set_id = option_sets.id
            LEFT OUTER JOIN option_nodes answer_opt_nodes ON answer_opt_nodes.id = answers.option_node_id
            LEFT OUTER JOIN options answer_options ON answer_options.id = answer_opt_nodes.option_id
            LEFT OUTER JOIN choices ON choices.answer_id = answers.id
            LEFT OUTER JOIN option_nodes choice_opt_nodes ON choice_opt_nodes.id = choices.option_node_id
            LEFT OUTER JOIN options choice_options ON choice_options.id = choice_opt_nodes.option_id
        SQL
      end

      def order
        <<~SQL.squish
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
