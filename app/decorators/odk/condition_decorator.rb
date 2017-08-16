module Odk
  class ConditionDecorator < ::ApplicationDecorator
    delegate_all

    def to_odk
      lhs = "/data/#{ref_subquestion.odk_code}"

      if ref_qing.has_options?
        selected = "selected(#{lhs}, '#{option_nodes.last.odk_code}')"
        %w(neq ninc).include?(operator[:name]) ? "not(#{selected})" : selected
      else
        if ref_qing.temporal?
          format = :"javarosa_#{ref_qing.qtype_name}"
          formatted = Time.zone.parse(value).to_s(format)
          lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
          rhs = "'#{formatted}'"
        else
          rhs = ref_qing.numeric? ? value : "'#{value}'"
        end
        "#{lhs} #{operator[:code]} #{rhs}"
      end
    end
  end
end
