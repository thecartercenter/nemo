# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for Forms
    class FormWarner < Warner
      protected

      def careful_with_changes
        [:published]
      end

      def features_disabled
        %i[published data]
      end
    end
  end
end
