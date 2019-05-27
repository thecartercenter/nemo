# frozen_string_literal: true

# Abstract class for searching a relation via query params.
class Searcher
  attr_accessor :relation, :query, :scope

  def initialize(relation:, query:, scope: nil)
    self.relation = relation
    self.query = query
    self.scope = scope
  end
end
