# frozen_string_literal: true

module OData
  class SimpleEntities
    attr_reader :values

    # TODO:
    #       <EntityType Name="Response.Form_A" BaseType="Demo.Response">
    #         <Property Name="FullName" Type="Edm.String"/>
    #         <Property Name="Age" Type="Edm.Int64"/>
    #       </EntityType>
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
        SimpleEntity.new("Responses: #{form.name}", extra_tags: {BaseType: base_type},
                                                    property_types: {
                                                    })
      end

      @values = [base_entity] + response_entities
    end
  end
end
