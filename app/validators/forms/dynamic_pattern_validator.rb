# frozen_string_literal: true

module Forms
  # Validates default response name, default answer, etc.
  class DynamicPatternValidator < ActiveModel::Validator
    def initialize(options)
      super
      self.field_name = options[:field_name]
      self.force_calc_if = options[:force_calc_if]
    end

    def validate(record)
      calc_must_wrap_all_of_default_response_name(record)
      force_calc_for_dollar_refs(record) if force_calc_if.present? && record.send(force_calc_if)
    end

    private

    attr_accessor :field_name, :force_calc_if

    def calc_must_wrap_all_of_default_response_name(record)
      return if record[field_name].blank?
      return unless record[field_name].include?("calc(")

      # Only barf if calc is not at start OR doesn't end with )
      return unless record[field_name].match?(/[^\s].*calc\(|[^)]\z/)
      record.errors.add(field_name, :calc_must_wrap_all)
    end

    # Makes sure the expression is wrapped in calc() if it uses any dollar references.
    def force_calc_for_dollar_refs(record)
      return if record[field_name].blank? || record[field_name].start_with?("calc(") ||
          !record[field_name].match?(Odk::DynamicPatternParser::CODE_REGEX)
      record.errors.add(field_name, :must_use_calc)
    end
  end
end
