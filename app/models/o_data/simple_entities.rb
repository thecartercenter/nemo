# frozen_string_literal: true

module OData
  class SimpleEntities
    attr_reader :values

    def initialize(distinct_forms)
      @values = distinct_forms.map do |form|
        SimpleEntity.new("Responses: #{form.name}")
      end
    end
  end
end
