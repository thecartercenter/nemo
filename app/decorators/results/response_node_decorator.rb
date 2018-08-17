# frozen_string_literal: true

module Results
  class ResponseNodeDecorator < ApplicationDecorator
    delegate_all

    attr_accessor :form_context

    def initialize(object, form_context)
      self.form_context = form_context
      super(object)
    end

    def mode_class
      form_context.read_only? ? "read-only" : "editable"
    end
  end
end
