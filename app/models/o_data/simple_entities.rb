# frozen_string_literal: true

module OData
  class SimpleEntities
    attr_reader :values

    def initialize(distinct_forms)
      base_entity = SimpleEntity.new("Response", key_name: "ResponseID",
                                                 property_types: {
                                                   ResponseSubmitDate: :datetime,
                                                   ResponseSubmitterName: :string,
                                                   ResponseID: :string,
                                                   ResponseShortcode: :string,
                                                   ResponseReviewed: :boolean,
                                                   FormName: :string
                                                 })
      # TODO: Fix `warning: toplevel constant NAMESPACE referenced by ODataController::NAMESPACE`
      base_type = "#{ODataController::NAMESPACE}.Response"

      response_entities = distinct_forms.map do |form|
        property_types = form.questions.map do |q|
          [q.name, q.qtype.odata_type.to_sym]
        end.to_h
        SimpleEntity.new("Responses: #{form.name}", extra_tags: {BaseType: base_type},
                                                    property_types: property_types)
      end

      @values = [base_entity] + response_entities
    end
  end
end
