# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes an OptionNode for use in the Condition form.
  class OptionPathSerializer < ApplicationSerializer
    field :levels do |object|
      path = OptionNodePath.new(option_set: object.option_set, target_node: object)
      path.nodes_without_root.each_with_index.map do |_, i|
        {
          name: path.multilevel? ? path.level_name_for_depth(i + 1) : nil,
          selected: path.nodes[i + 1]&.id,
          options: path.nodes_for_depth(i + 1).map { |n| {name: n.name, id: n.id} }
        }
      end
    end
  end
end
