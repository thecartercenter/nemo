# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for OptionSets
    class OptionSetWarner < Warner
      protected

      # See Warner#warnings for more info on the expected return value here.
      def careful_with_changes
        [{in_use: :count}, :published, :standard_copy]
      end

      def features_disabled
        %i[published data]
      end

      def count
        object.questions.count
      end
    end
  end
end
