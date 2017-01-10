# Models the path of OptionNodes from the top level of an OptionSet to a given OptionNode.
# e.g. U.S.A -> Georgia -> Atlanta.
# Not persisted, just used for convenience in model and view logic.
class OptionNodePath
  attr_accessor :target_node, :nodes

  delegate :option_set, to: :target_node
  delegate :multilevel?, :level_name_for_depth, :level_count, to: :option_set

  def initialize(attribs = {})
    attribs.each{ |k,v| instance_variable_set("@#{k}", v) }
    ensure_nodes_for_all_levels
  end

  def blank?
    nodes.all?(&:nil?)
  end

  # Returns the available options for the node at the given depth.
  # Depth 0 makes no sense as it's the root.
  def options_for_depth(depth)
    raise ArgumentError.new("depth must be > 1") if depth < 1
    raise ArgumentError.new("depth is too large") if depth >= nodes.size
    nodes[depth - 1].try(:child_options) || []
  end

  def option_ids_with_no_nils
    nodes_without_root.compact.map(&:option_id)
  end

  private

  def nodes_without_root
    nodes[1..-1]
  end

  # Ensures there are either OptionNode objects or nils for each level in the OptionSet (including root).
  def ensure_nodes_for_all_levels
    self.nodes ||= target_node.ancestors << target_node
    level_count.times.each { |i| nodes[i + 1] ||= nil }
  end
end
