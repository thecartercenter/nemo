# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for OptionLevels
    class OptionLevelWarner < Warner
      protected

      # See Warner#warnings for more info on the expected return value here.
      def careful_with_changes
        %i[in_use published standard_copy]
      end

      def features_disabled
        []
      end
    end
  end
end
