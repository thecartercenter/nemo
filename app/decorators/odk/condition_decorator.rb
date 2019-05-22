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
      if left_qing.select_multiple?
        select_multiple_to_odk
      elsif left_qing.temporal? && right_side_is_literal?
        temporal_to_odk
      else
        other_types_to_odk
      end
    end

    def questioning
      decorate(object.conditionable)
    end

    def left_qing
      decorate(object.left_qing)
    end

    private

    def select_multiple_to_odk
      selected = "selected(#{left_xpath}, '#{option_node.odk_code}')"
      %w[neq ninc].include?(op) ? "not(#{selected})" : selected
    end

    def temporal_to_odk
      format = :"javarosa_#{left_qing.qtype_name}"
      formatted = Time.zone.parse(value).to_s(format)
      left = "format-date(#{left_xpath}, '#{Time::DATE_FORMATS[format]}')"
      right = "'#{formatted}'"
      join_with_operator(left, right)
    end

    def other_types_to_odk
      left = left_xpath
      right = if right_side_is_qing?
                right_xpath
              else
                left_qing.numeric? ? value : "'#{option_node&.odk_code || value}'"
              end
      join_with_operator(left, right)
    end

    def join_with_operator(left, right)
      "#{left} #{OP_XPATH[op.to_sym]} #{right}"
    end

    def left_xpath
      questioning.xpath_to(ref_subqing)
    end

    def right_xpath
      questioning.xpath_to(right_qing)
    end
  end
end
