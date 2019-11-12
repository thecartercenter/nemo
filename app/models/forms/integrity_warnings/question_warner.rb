# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for QingGroups
    class QuestionWarner < Warner
      protected

      # See Warner#warnings for more info on the expected return value here.
      def careful_with_changes
        [{in_use: :form_list}, :published, :standard_copy]
      end

      def features_disabled
        # We include standard_copy here because editing the question code is not allowed
        # for standard copies.
        %i[published data standard_copy]
      end
    end
  end
end
