# frozen_string_literal: true

# represents an expression in the parsed search
# consists of an optional qualifier and a string of values
class Search::Expression
  attr_accessor :qualifier, :qualifier_text, :op, :values, :leaves

  def initialize(attribs = {})
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
  end
end
