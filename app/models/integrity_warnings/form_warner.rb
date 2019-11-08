# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for Forms
  class FormWarner
    attr_accessor :form

    def initialize(form)
      self.form = form
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def careful_with_changes
      form.published? ? [:published] : []
    end

    # See IntegrityWarnings::Builder#text for more info on the expected return value here.
    def features_disabled
      [form.published? ? :published : nil, form.responses.any? ? :has_data : nil].compact
    end
  end
end
