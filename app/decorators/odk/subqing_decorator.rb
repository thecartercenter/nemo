module Odk
  class SubqingDecorator < BaseDecorator
    delegate_all
    delegate :top_level?, :ancestors, :ancestor_ids, :path_from_ancestor, :multilevel?,
      to: :decorated_questioning

    # If options[:previous] is true, returns the code for the
    # immediately previous subqing (multilevel only).
    def odk_code(options = {})
      base = decorated_questioning.odk_code
      if multilevel?
        r = options[:previous] ? rank - 1 : rank
        "#{base}_#{r}"
      else
        base
      end
    end

    def absolute_xpath
      (decorate(ancestors.to_a) << self).map(&:odk_code).join("/")
    end

    def decorated_questioning
      @decorated_questioning ||= Odk::DecoratorFactory.decorate(object.questioning)
    end
  end
end
