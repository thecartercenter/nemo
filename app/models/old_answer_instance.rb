# A set of OldAnswerNodes corresponding to one repeat instance of a QingGroup.
# See AnswerArranger for more documentation.
class OldAnswerInstance
  attr_accessor :nodes, :num, :placeholder, :root
  alias_method :placeholder?, :placeholder
  alias_method :root?, :root

  def initialize(params)
    self.num = params[:num]
    self.nodes = params[:nodes]
    self.root = params[:root] || false
    self.placeholder = params[:placeholder] || false

    if placeholder?
      self.num = "__INST_NUM__" # Used as placeholder
    end
  end

  # Ensures contiguous inst_num for all instances.
  # Marks blank instances for destruction.
  # Recurses to all child instances.
  def normalize
    mark_for_destruction if blank? && !root?
    nodes.each { |node| node.normalize }
  end

  def leaf_nodes
    nodes.map { |node| node.leaf? ? node : node.descendant_leaves }.flatten
  end

  def update_inst_num(num)
    nodes.each { |node| node.update_inst_num(num) }
  end

  def blank?
    nodes.empty? || nodes.all?(&:blank?)
  end

  def mark_for_destruction
    nodes.each(&:mark_for_destruction)
  end

  def marked_for_destruction?
    nodes.all?(&:marked_for_destruction?)
  end
end
