# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for QingGroups
  class QingGroupWarner
    attr_accessor :group

    def initialize(group)
      self.group = group
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def careful_with_changes
      warnings = []
      warnings << :published if group.published?
      warnings << :standard_copy if group.standardized?
      warnings
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def features_disabled
      []
    end
  end
end
