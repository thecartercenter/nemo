module TreeTraverseable
  extend ActiveSupport::Concern

  def lowest_common_ancestor(other)
    ancestor_id = (self.ancestor_ids & other.ancestor_ids).last
    self.ancestors.find(ancestor_id)
  end

  def path_from_ancestor(ancestor, include_ancestor: false, include_self: false)
    ancestor_list = self.ancestors
    # find ancestor
    i = ancestor_list.find_index { |a| a.id == ancestor.id }

    i += 1 unless include_ancestor
    ancestor_list << self if include_self

    ancestor_list[i..-1]
  end

  def self_and_ancestors
    ancestors << self
  end
end
