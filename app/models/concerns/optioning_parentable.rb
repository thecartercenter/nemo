module OptioningParentable
  extend ActiveSupport::Concern

  protected
    # makes sure, recursively, that the options in the set have sequential ranks starting at 1.
    def ensure_children_ranks
      children.ensure_contiguous_ranks
      children.each{|c| c.ensure_children_ranks}
    end
end