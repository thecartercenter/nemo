# frozen_string_literal: true

module Forms
  # Validates default response name, default answer, etc.
  class DynamicPatternValidator < ActiveModel::Validator
    def initialize(options)
      super
      self.field_name = options[:field_name]
    end

    def validate(record)
      calc_must_wrap_all_of_default_response_name(record)
    end

    private

    attr_accessor :field_name

    def calc_must_wrap_all_of_default_response_name(record)
      return if record[field_name].blank?
      return unless record[field_name].match?(/[^\s].*calc\(|\).*[^\s].*\z/)
      record.errors.add(field_name, :calc_must_wrap_all)
    end
  end
end
