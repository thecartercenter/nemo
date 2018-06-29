module TreeTraverseable
  extend ActiveSupport::Concern

  def lowest_common_ancestor(other)
    ancestor_id = (self.self_and_ancestor_ids & other.self_and_ancestor_ids).last
    ancestor_id == id ? self : self.ancestors.find(ancestor_id)
  end

  # Gets path from ancestor to self. ancestor may be self.
  def path_from_ancestor(ancestor, include_ancestor: false, include_self: false)
    return [self] if ancestor == self

    ancestor_list = self.ancestors.to_a
    # find ancestor
    i = ancestor_list.find_index { |a| a.id == ancestor.id }

    i += 1 unless include_ancestor
    ancestor_list << self if include_self

    ancestor_list[i..-1]
  end

  def self_and_ancestors
    ancestors.to_a << self
  end
end
