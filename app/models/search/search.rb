# frozen_string_literal: true

# Knows how to convert a query string + qualifiers into SQL.
#
# See also Searcher which can apply more complex logic.
class Search::Search
  attr_accessor :str, :qualifiers, :expressions

  def initialize(attribs = {})
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
    @expressions = []
    @parser = Search::Parser.new(search: self)
    @parser.parse
  end

  # returns the generated sql
  def sql
    @parser.sql
  end

  def associations
    @associations ||= expressions.map { |e| e.qualifier.assoc }.flatten.compact.uniq
  end

  def uses_qualifier?(qualifier_name)
    expressions.any? { |e| e.qualifier.name == qualifier_name }
  end
end
