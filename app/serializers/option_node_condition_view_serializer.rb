class OptionNodeConditionViewSerializer < ActiveModel::Serializer
  attributes :levels
  format_keys :lower_camel

  def levels
    path = OptionNodePath.new(option_set: object.option_set, target_node: object)
    path.nodes_without_root.each_with_index.map do |node, i|
      {
        name: path.multilevel? ? path.level_name_for_depth(i + 1) : nil,
        selected: path.nodes[i + 1].try(:id),
        options: path.nodes_for_depth(i + 1).map { |n| {name: n.option_name, id: n.id } }
      }
    end
  end
end
