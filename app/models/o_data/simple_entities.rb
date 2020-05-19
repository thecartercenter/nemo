# frozen_string_literal: true

module OData
  # Represents all the OData entities for our metadata.
  class SimpleEntities
    attr_reader :values

    def initialize(distinct_forms)
      base_entity = SimpleEntity.new("Response", key_name: "ResponseID",
                                                 property_types: {
                                                   ResponseSubmitDate: :datetime,
                                                   ResponseSubmitterName: :string,
                                                   ResponseID: :id,
                                                   ResponseShortcode: :string,
                                                   ResponseReviewed: :boolean,
                                                   FormName: :string
                                                 })
      # TODO: Fix `warning: toplevel constant NAMESPACE referenced by ODataController::NAMESPACE`
      base_type = "#{ODataController::NAMESPACE}.Response"

      response_entities = distinct_forms.map do |form|
        add_children(parent: form, parent_name: "Responses: #{form.name}", base_type: base_type, root_name: form.name)
      end.flatten

      @values = [base_entity] + response_entities
    end

    # Add an Entity for each of the parent's children,
    # recursing into groups.
    def add_children(parent:, parent_name:, base_type: nil, root_name: nil, children: [])
      group_number = 0
      property_types = parent.c.map do |c|
        if c.is_a?(QingGroup)
          group_number += 1
          entity_name = get_entity_name(root_name, group_number, parent_name)
          add_children(parent: c, parent_name: entity_name, children: children)
          child_name = "#{ODataController::NAMESPACE}.#{entity_name}"
          child_type = c.repeatable? ? "Collection(#{child_name})" : child_name
          ["#{c.group_name} (#{group_number})", child_type]
        else
          [c.name, c.qtype.odata_type.to_sym]
        end
      end.to_h

      children.push(SimpleEntity.new(parent_name, extra_tags: base_type ? {BaseType: base_type} : {},
                                                  property_types: property_types))
    end

    # Return the OData EntityType name for a group based on its nesting.
    def get_entity_name(root_name, group_number, parent_name)
      if root_name
        # The first level starts with the word "Group"
        "Group.#{root_name}.G#{group_number}"
      else
        # Each level of nesting after that is just one more `.G#` at the end.
        "#{parent_name}.G#{group_number}"
      end
    end
  end
end
