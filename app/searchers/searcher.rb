# frozen_string_literal: true

# Abstract class for searching a relation via query params.
class Searcher
  attr_accessor :relation, :query, :scope, :options

  def initialize(relation, query, scope, options = nil)
    self.relation = relation
    self.query = query
    self.scope = scope
    self.options = options
  end
end
