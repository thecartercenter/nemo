# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for QingGroups
  class QuestionWarner < Warner
    protected

    # See IntegrityWarnings::Warner#warnings for more info on the expected return value here.
    def careful_with_changes
      [[:in_use, :form_list], :published, :standardized]
    end

    def features_disabled
      %i[published data]
    end
  end
end
