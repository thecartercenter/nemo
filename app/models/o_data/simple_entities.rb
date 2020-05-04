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
        add_children(parent: form, parent_name: "Responses: #{form.name}", base_type: base_type, root_name: form.name)
      end.flatten

      @values = [base_entity] + response_entities
    end

    # Add an Entity for each of the parent's children,
    # recursing into repeat groups.
    def add_children(parent:, parent_name:, base_type: nil, root_name: nil, children: [])
      repeat_number = 0
      property_types = parent.c.map do |c|
        if c.is_a?(QingGroup)
          repeat_number += 1
          name = get_repeat_name(root_name, repeat_number, parent_name)
          add_children(parent: c, parent_name: name, children: children)
          [c.group_name, "Collection(#{ODataController::NAMESPACE}.#{name})"]
        else
          [c.name, c.qtype.odata_type.to_sym]
        end
      end.to_h

      children.push(SimpleEntity.new(parent_name, extra_tags: base_type ? {BaseType: base_type} : {},
                                                  property_types: property_types))
    end

    # Return the OData EntityType name for a repeat group based on its nesting.
    def get_repeat_name(root_name, repeat_number, parent_name)
      if root_name
        # The first level of repeats starts with the word "Repeat"
        "Repeat.#{root_name}.R#{repeat_number}"
      else
        # Each level of nesting after that is just one more `.R#` at the end.
        "#{parent_name}.R#{repeat_number}"
      end
    end
  end
end
