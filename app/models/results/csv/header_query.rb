# frozen_string_literal: true

module Results
  module Csv
    # The query to get the expected headers.
    class HeaderQuery < Query
      protected

      def select
        <<~SQL
          SELECT DISTINCT
            questions.code,
            questions.qtype_name,
            option_sets.level_names,
            option_sets.allow_coordinates,
            answers.rank,
            LOWER(questions.code)
        SQL
      end

      def from
        <<~SQL
          FROM responses
            INNER JOIN answers ON answers.response_id = responses.id
            INNER JOIN form_items qings ON answers.questioning_id = qings.id
            INNER JOIN questions ON qings.question_id = questions.id
            LEFT OUTER JOIN option_sets ON questions.option_set_id = option_sets.id
        SQL
      end

      def where
        ""
      end

      def order
        <<~SQL
          ORDER BY LOWER(questions.code)
        SQL
      end
    end
  end
end
