# frozen_string_literal: true

module Results
  class ResponseNodeDecorator < ApplicationDecorator
    delegate_all

    attr_accessor :form_context

    def self.decorate(node, context)
      "::Results::#{node.class}Decorator".constantize.new(node, context)
    end

    def initialize(object, form_context)
      self.form_context = form_context
      super(object)
    end

    private

    def mode_class
      form_context.read_only? ? "read-only" : "editable"
    end

    def error_class
      "with-error" if invalid?
    end
  end
end
