module Results
  module Csv
    class QA
      include CSVHelper

      def initialize(question, answers, cache)
        @question = question
        @answers = answers
        @answer = answers.first
        @question_type = question.qtype_name
        @cache = cache
      end

      def cells
        arr = case question_type
        when 'select_one'
          arr = answers.map { |a| format_csv_para_text(a.option_name) }
          if cache[question, :multilevel?]
            arr += ([nil] * (question.level_count - arr.size))
          end
          if question.geographic?
            arr += lat_lng(answers.last)
          end
          arr
        when 'location'
          lat_lng(answer)
        when 'datetime'
          [answer.casted_value.try(:to_s, :std_datetime_with_tz)]
        when 'date', 'time'
          [answer.casted_value.try(:to_s, :"std_#{question_type}")]
        else
          [format_csv_para_text(answer.casted_value)]
        end
      end

      private

      attr_accessor :question, :answers, :answer, :question_type, :cache

      def lat_lng(ans)
        ans.lat_lng || [nil, nil]
      end
    end
  end
end
