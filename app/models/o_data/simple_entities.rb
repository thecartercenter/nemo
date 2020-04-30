# frozen_string_literal: true

module OData
  class SimpleEntities
    attr_reader :values

    # TODO:
    #       <EntityType Name="Response.Form_C" BaseType="Demo.Response">
    #         <Property Name="City" Type="Edm.String"/>
    #         <Property Name="HouseholdMembers" Type="Collection(Demo.Repeat.Form_C.R1)"/>
    #       </EntityType>
    #       <EntityType Name="Repeat.Form_B.R1">
    #         <Property Name="FullName" Type="Edm.String"/>
    #         <Property Name="Age" Type="Edm.Int64"/>
    #         <Property Name="Eyes" Type="Collection(Demo.Repeat.Form_B.R2)"/>
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
        repeat_number = 0
        property_types = form.c.map do |c|
          c.is_a?(Questioning) ?
            [c.name, c.qtype.odata_type.to_sym] :
            [c.group_name, "Collection(#{ODataController::NAMESPACE}.Repeat.#{form.name}.R#{repeat_number += 1})"]
        end.to_h
        SimpleEntity.new("Responses: #{form.name}", extra_tags: {BaseType: base_type},
                                                    property_types: property_types)
      end

      @values = [base_entity] + response_entities
    end
  end
end
