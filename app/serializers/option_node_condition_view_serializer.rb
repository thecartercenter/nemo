class OptionNodeConditionViewSerializer < ActiveModel::Serializer
  attributes :levels

  def levels
    path = OptionNodePath.new(option_set: object.option_set, target_node: object)

    levels = path.nodes_without_root.each_with_index.map do |node, i|
      puts i
      puts path.nodes_for_depth(i + 1)
      {
        name: path.multilevel? ? path.level_name_for_depth(i + 1) : nil,
        selected: path.nodes[i+1].try(:option).try(:id),
        options: path.nodes_for_depth(i+1).map {|n| {name: n.option.name, id: n.option.id}} #TO DO Translation
      }
    end
    levels
  end
end
