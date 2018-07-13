module Odk
  class SubqingDecorator < BaseDecorator
    # Delegation was working strangely here so we're doing it manually instead of using delegate_all.
    # We are delegating to two places -- these specific methods to the underlying Subqing,
    # and everything else (via method_missing) to the decorated Questioning.
    delegate :name, :rank, :level, :first_rank?, to: :object

    # If options[:previous] is true, returns the code for the
    # immediately previous subqing (multilevel only).
    def odk_code(options = {})
      CodeMapper.instance.code_for_item(object, options)
    end

    def absolute_xpath
      (decorate_collection(ancestors.to_a) << self).map(&:odk_code).join("/")
    end

    def decorated_questioning
      @decorated_questioning ||= decorate(object.questioning)
    end

    def method_missing(*args)
      decorated_questioning.send(*args)
    end
  end
end
