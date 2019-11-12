# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for QingGroups
  class QingGroupWarner < Warner
    protected

    def careful_with_changes
      %i[published standard_copy]
    end

    def features_disabled
      []
    end
  end
end
