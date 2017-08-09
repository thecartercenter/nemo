module TreeTraverseable
  extend ActiveSupport::Concern

  def lowest_common_ancestor(other)
    ancestor_id = (self.ancestor_ids & other.ancestor_ids).last
    self.ancestors.find(ancestor_id)
  end

  def path_to_ancestor(ancestor)
    i = ancestors.find_index { |a| a.id == ancestor.id }
    ancestors[i..-1]
  end

  def self_and_ancestors
    ancestors << self
  end
end
