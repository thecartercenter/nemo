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
      force_calc_for_dollar_refs(record) if force_calc_if&.call(record)
      refd_option_set_must_exist(record)
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
        !record[field_name].match?(ODK::DynamicPatternParser::CODE_REGEX)
      record.errors.add(field_name, :must_use_calc)
    end

    # Makes sure all $QuestionCode:value expressions refer to a question with a valid option set.
    def refd_option_set_must_exist(record)
      question_codes = record[field_name].scan(ODK::DynamicPatternParser::CODE_ONLY_REGEX).flatten
      errors = question_codes.map { |code| validate_option_set(code) }.compact
      errors.each { |error| record.errors.add(field_name, error) }
    end

    # Returns an error translation key if there's an error, or nil if valid.
    def validate_option_set(question_code)
      q = Question.find_by(code: question_code)
      return :value_ref_nonexistent if q.nil?
      return :value_ref_wrong_type if q.qtype_name != "select_one"
    end
  end
end
