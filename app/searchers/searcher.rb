# frozen_string_literal: true

# Abstract class for searching a relation via query params.
#
# See also Search::Search which is simpler and just deals with SQL.
class Searcher
  # Search params
  attr_accessor :relation, :query, :scope

  # Parsed search values
  attr_accessor :form_ids, :advanced_text

  def initialize(relation:, query:, scope: nil)
    self.relation = relation
    self.query = query
    self.scope = scope
    self.form_ids = []
    self.advanced_text = ""
  end
end
