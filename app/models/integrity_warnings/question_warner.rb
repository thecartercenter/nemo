# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for QingGroups
  class QuestionWarner
    attr_accessor :object

    def initialize(object)
      self.object = object
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def careful_with_changes
      warnings = []
      warnings << [:in_use, forms: form_list] if object.forms.any?
      warnings << :published if object.published?
      warnings << :standard_copy if object.standard_copy?
      warnings
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def features_disabled
      warnings = []
      warnings << :published if object.published?
      warnings << :has_data if object.has_answers?
      warnings
    end

    private

    def form_list
      form_count = object.forms.size
      more_suffix = form_count > 3 ? I18n.t("integrity_warnings.more_suffix", count: form_count - 3) : nil
      [object.forms.map(&:name).join(", "), more_suffix].compact.join(" ")
    end
  end
end
