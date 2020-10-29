# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for OptionSets
    class OptionSetWarner < Warner
      protected

      # See Warner#warnings for more info on the expected return value here.
      def careful_with_changes
        [
          [:in_use, {i18n_params: -> { {question_list: question_list} }}],
          :published,
          :standard_copy
        ]
      end

      def features_disabled
        %i[published data]
      end

      def question_list
        question_count = object.questions.count
        more_suffix =
          if question_count > MAX_QUESTIONS
            str = I18n.t("integrity_warnings.more_suffix", count: question_count - MAX_QUESTIONS)
            "(+#{str})"
          end
        [object.questions.by_code[0...MAX_QUESTIONS].map(&:code).join(", "), more_suffix].compact.join(" ")
      end
    end
  end
end
