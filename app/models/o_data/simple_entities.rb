# frozen_string_literal: true

module OData
  # Represents all the OData entities for our metadata.
  class SimpleEntities
    attr_accessor :values

    RESPONSE_BASE_PROPERTIES = {
      ResponseSubmitDate: :datetime,
      ResponseSubmitterName: :string,
      ResponseID: :id,
      ResponseShortcode: :string,
      ResponseReviewed: :boolean,
      FormName: :string
    }.freeze

    def initialize(distinct_forms)
      response_base = SimpleEntity.new("Response", key_name: "ResponseID",
                                                   property_types: RESPONSE_BASE_PROPERTIES)
      response_entities = distinct_forms.map do |form|
        build_nested_children(parent: form,
                              parent_name: "Responses: #{form.name}",
                              base_type: "#{SimpleSchema::NAMESPACE}.Response",
                              root_name: form.name)
      end.flatten

      self.values = [response_base] + response_entities
    end

    # Add an Entity for each of the parent's children, recursing into groups.
    def build_nested_children(parent:, parent_name:, base_type: nil, root_name: nil, children: [])
      group_number = 0
      property_types = parent.sorted_children.map do |child|
        if child.is_a?(QingGroup)
          group_number += 1
          child_qing_group(child, group_number: group_number, parent_name: parent_name,
                                  root_name: root_name, children: children)
        else
          child_qing(child)
        end
      end.to_h

      children.push(SimpleEntity.new(parent_name, extra_tags: base_type ? {BaseType: base_type} : {},
                                                  property_types: property_types))
    end

    def child_qing_group(child, group_number:, parent_name:, root_name:, children:)
      entity_name = entity_name_for(root_name, group_number, parent_name)
      build_nested_children(parent: child, parent_name: entity_name, children: children)
      child_name = "#{SimpleSchema::NAMESPACE}.#{entity_name}"
      child_type = child.repeatable? ? "Collection(#{child_name})" : child_name
      # TODO: Remove `(group_number)` once we use unique group_code in an upcoming commit.
      ["#{child.group_name} (#{group_number})", child_type]
    end

    def child_qing(child)
      qtype = OData::QuestionType.new(child.qtype)
      [child.name, qtype.odata_type]
    end

    # Return the OData EntityType name for a group based on its nesting.
    def entity_name_for(root_name, group_number, parent_name)
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
