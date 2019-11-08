# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for Forms
  class FormWarnings
    attr_accessor :form

    def initialize(form)
      self.form = form
    end

    def careful_with_changes
      form.published? ? [:published] : []
    end

    def features_disabled
      [form.published? ? :published : nil, form.responses.any? ? :has_data : nil].compact
    end
  end
end
