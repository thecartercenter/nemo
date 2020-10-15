# frozen_string_literal: true

module ODK
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
      if left_qing.select_multiple? && right_side_is_literal?
        select_multiple_to_odk
      elsif left_qing.temporal? && right_side_is_literal?
        temporal_to_odk
      else
        other_types_to_odk
      end
    end

    def questioning
      decorate(object.conditionable.base_item)
    end

    def left_qing
      decorate(object.left_qing)
    end

    def right_qing
      decorate(object.right_qing)
    end

    private

    def select_multiple_to_odk
      selected = "selected(#{left_actual}, '#{option_node.odk_code}')"
      %w[neq ninc].include?(op) ? "not(#{selected})" : selected
    end

    def temporal_to_odk
      format = :"javarosa_#{left_qing.qtype_name}"
      formatted = Time.zone.parse(value).to_s(format)
      left = "format-date(#{left_actual}, '#{Time::DATE_FORMATS[format]}')"
      right = "'#{formatted}'"
      join_with_operator(left, right)
    end

    def other_types_to_odk
      left = left_actual(coalesce_multilevel: right_side_is_qing?)
      right = if right_side_is_qing?
                right_actual
              else
                left_qing.numeric? ? value : "'#{option_node&.odk_code || value}'"
              end
      join_with_operator(left, right)
    end

    def join_with_operator(left, right)
      "#{left} #{OP_XPATH[op.to_sym]} #{right}"
    end

    def left_actual(coalesce_multilevel: false)
      if coalesce_multilevel
        multilevel_coalesce_expr(left_qing)
      elsif option_node.present?
        # If we're not coalescing and there is a literal option_node,
        # we get the xpath to the same level as the option node.
        # This way if the condition refers to Canada > Ontario and the answered value
        # is Canada > Ontario > Kingston, the condition will still be true.
        questioning.xpath_to(left_qing.subqings[option_node.depth - 1])
      else
        questioning.xpath_to(left_qing)
      end
    end

    def right_actual
      # We always coalesce when there is a right_qing because the bottommost selection is a stand-in for the
      # whole answer value.
      multilevel_coalesce_expr(right_qing)
    end

    # Builds an expression that searches from the bottom up in a multilevel question for a non-empty value.
    # Example output: coalesce(coalesce(/data/qing1234_3, /data/qing1234_2), /data/qing1234_1))
    def multilevel_coalesce_expr(qing)
      return questioning.xpath_to(qing) unless qing.multilevel?
      qing.subqings.reverse.inject(nil) do |expr, subq|
        xpath = questioning.xpath_to(subq)
        expr.nil? ? xpath : "coalesce(#{expr}, #{xpath})"
      end
    end
  end
end
