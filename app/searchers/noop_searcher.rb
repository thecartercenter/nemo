# frozen_string_literal: true

# Class that acts as a pass-through Searcher.
# It simply returns the original relation when applied.
class NoopSearcher < Searcher
  def apply
    relation
  end
end
