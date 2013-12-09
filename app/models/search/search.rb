class Search::Search
  attr_accessor :str, :qualifiers, :expressions

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    @expressions = []
    @parser = Search::Parser.new(:search => self)
    @parser.parse
  end

  # returns the generated sql
  def sql
    @parser.sql
  end

  def associations
    expressions.map{|e| e.qualifier.assoc}.flatten.compact.uniq
  end
end