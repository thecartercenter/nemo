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
      lhs = questioning.xpath_to(ref_subqing)

      if ref_qing.has_options?
        selected = "selected(#{lhs}, '#{option_node.odk_code}')"
        %w[neq ninc].include?(op) ? "not(#{selected})" : selected
      else
        if ref_qing.temporal?
          format = :"javarosa_#{ref_qing.qtype_name}"
          formatted = Time.zone.parse(value).to_s(format)
          lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
          rhs = "'#{formatted}'"
        else
          rhs = ref_qing.numeric? ? value : "'#{value}'"
        end
        "#{lhs} #{OP_XPATH[op.to_sym]} #{rhs}"
      end
    end

    def questioning
      decorate(object.conditionable)
    end

    def ref_qing
      decorate(object.ref_qing)
    end
  end
end
