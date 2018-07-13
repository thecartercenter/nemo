# frozen_string_literal: true

module Odk
  class BaseDecorator < ::ApplicationDecorator
    delegate_all

    protected

    def tag(name, attribs = {})
      # Rails automatically sets some attribs like required to "required", regardless of what you pass.
      # The below fixes this by changing the keys to e.g. _required, rendering the tag, and then
      # changing them back.
      to_fix = %i[required readonly]
      fixed_attribs = ActiveSupport::OrderedHash.new
      attribs.each do |key, val|
        fixed_key = to_fix.include?(key) ? :"_#{key}" : key
        fixed_attribs[fixed_key] = val
      end

      # I think html_safe is unavoidable here because we are hacking the attribs.
      h.tag(name, fixed_attribs).sub(/_(#{to_fix.join('|')})=/, '\1=').html_safe
    end

    def content_tag(*args)
      h.content_tag(*args)
    end

    def decorate(obj, context: {})
      DecoratorFactory.decorate(obj, context: context)
    end

    def decorate_collection(objs, context: {})
      DecoratorFactory.decorate_collection(objs, context: context)
    end
  end
end
