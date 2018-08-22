# frozen_string_literal: true

module Results
  class ResponseNodeDecorator < ApplicationDecorator
    delegate_all

    attr_accessor :form_context

    def self.decorate(node, form_context = nil)
      "::Results::#{node.class}Decorator".constantize.new(node, form_context)
    end

    def initialize(object, form_context = nil)
      self.form_context = form_context
      super(object)
    end

    def child_context(index)
      if root?
        form_context
      else
        form_context.add(index, visible: !object.is_a?(AnswerGroupSet))
      end
    end

    private

    def mode_class
      require_context
      form_context.read_only? ? "read-only" : "editable"
    end

    def error_class
      "with-error" if invalid?
    end

    def require_context
      raise "Form context required for this method" if form_context.nil?
    end
  end
end
