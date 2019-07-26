# frozen_string_literal: true

# Abstract class for searching a relation via query params.
#
# See also Search::Search which is simpler and just deals with SQL.
class Searcher
  include ActiveModel::Serialization

  # Search params
  attr_accessor :relation, :query, :scope

  # Generic parsed search values
  attr_accessor :advanced_text

  def initialize(relation:, query:, scope: nil)
    self.relation = relation
    self.query = query
    self.scope = scope
    self.advanced_text = +""
  end
end
