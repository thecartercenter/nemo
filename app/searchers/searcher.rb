# frozen_string_literal: true

# Abstract class for searching a relation via query params.
#
# See also Search::Search which is simpler and just deals with SQL.
class Searcher
  attr_accessor :relation, :query, :scope

  def initialize(relation:, query:, scope: nil)
    self.relation = relation
    self.query = query
    self.scope = scope
  end
end
