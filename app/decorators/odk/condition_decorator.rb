# frozen_string_literal: true

module Odk
  # Converts condition to xpath for ODK.
  class ConditionDecorator < BaseDecorator
    delegate_all

    OP_XPATH = {
      eq: "=",
      lt: "<",
      gt: ">",
      leq: "<=",
      geq: ">=",
      neq: "!=",
      inc: "=",
      ninc: "!="
    }.freeze

    def to_odk
      return "true()" if right_side_is_qing?
      lhs = questioning.xpath_to(ref_subqing)
      left_qing.has_options? ? select_to_odk(lhs) : non_select_to_odk(lhs)
    end

    def questioning
      decorate(object.conditionable)
    end

    def left_qing
      decorate(object.left_qing)
    end

    private

    def select_to_odk(lhs)
      selected = "selected(#{lhs}, '#{option_node.odk_code}')"
      %w[neq ninc].include?(op) ? "not(#{selected})" : selected
    end

    def non_select_to_odk(lhs)
      if left_qing.temporal?
        format = :"javarosa_#{left_qing.qtype_name}"
        formatted = Time.zone.parse(value).to_s(format)
        lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
        rhs = "'#{formatted}'"
      else
        rhs = left_qing.numeric? ? value : "'#{value}'"
      end
      "#{lhs} #{OP_XPATH[op.to_sym]} #{rhs}"
    end
  end
end
