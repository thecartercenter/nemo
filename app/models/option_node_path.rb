# Models the path of OptionNodes from the top level of an OptionSet to a given OptionNode.
# e.g. U.S.A -> Georgia -> Atlanta.
# Accepts an explicit OptionSet attribute for cases where target_node is nil.
# Not persisted, just used for convenience in model and view logic.
class OptionNodePath
  attr_accessor :option_set, :target_node, :nodes

  delegate :multilevel?, :level_name_for_depth, :level_count, to: :option_set

  def initialize(attribs = {})
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
    if !target_node.nil? && option_set != target_node.option_set
      raise ArgumentError.new("target_node's OptionSet doesn't match given OptionSet")
    end
    ensure_nodes_for_all_levels
  end

  def blank?
    target_node.nil?
  end

  # Returns the available child nodes at the given depth in the path.
  # Depth 0 makes no sense as it's the root.
  def nodes_for_depth(depth)
    raise ArgumentError.new("depth must be > 1") if depth < 1
    raise ArgumentError.new("depth is too large") if depth >= nodes.size
    nodes[depth - 1].try(:sorted_children) || []
  end

  def nodes_without_root
    nodes[1..-1]
  end

  private

  # Ensures there are either OptionNode objects or nils for each level in the OptionSet (including root).
  # If target_node is nil, still includes the root node in the array.
  def ensure_nodes_for_all_levels
    self.nodes ||= target_node ? target_node.ancestors.to_a << target_node : [option_set.root_node]
    level_count.times.each { |i| nodes[i + 1] ||= nil }
  end
end
