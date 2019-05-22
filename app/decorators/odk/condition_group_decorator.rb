# frozen_string_literal: true

module Odk
  class ConditionGroupDecorator < BaseDecorator
    # Returns nil if there are no members and negate is false. nil means 'true'.
    def to_odk
      if members.empty?
        negate? ? "false()" : nil
      else
        conjunction = true_if == "all_met" ? I18n.t("common.and") : I18n.t("common.or")
        result = decorated_members.map { |m| "(#{m.to_odk})" }.join(" #{conjunction} ")
        negate? ? "not(#{result})" : result
      end
    end

    private

    def decorated_members
      # Don't use draper decorate_collection so we can mock in tests
      members.map { |m| Odk::DecoratorFactory.decorate(m) }
    end
  end
end
