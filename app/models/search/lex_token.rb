class Search::LexToken
  attr_reader(:kind, :content, :fragment)
  
  # array of lex token kinds, in the order by which they should be searched
  EQUAL = {:name => :equal, :pattern => "="}
  KINDS = [
    {:name => :colon, :pattern => ":", :sql => "="},
    EQUAL,
    {:name => :gt, :pattern => ">"},
    {:name => :lt, :pattern => "<"},
    {:name => :gteq, :pattern => ">="},
    {:name => :lteq, :pattern => "<="},
    {:name => :gtlt, :pattern => "<>"},
    {:name => :noteq, :pattern => "!="},
    {:name => :lparen, :pattern => "("},
    {:name => :rparen, :pattern => ")"},
    {:name => :comma, :pattern => ","},
    {:name => :and, :pattern => /and/i, :sql => "AND"},
    {:name => :or, :pattern => /or/i, :sql => "OR"},
    {:name => :string, :pattern => /"([^"]*?[^\\"]|)"/, :sub_idx => 1},
    {:name => :chunk, :pattern => /[^\s:=<>!,)]+/}
  ]
    
  def initialize(defn, content = "", fragment = "")
    @kind = defn[:name]
    @content, @fragment = content, fragment
    @sql = (defn[:sql] || @content || "")
  end

  def is?(kind); @kind == kind; end
  def to_s; "#{@kind}(#{@content})"; end
  def to_sql; @sql; end
  def to_s_indented(level = 0); ("  " * level) + to_s; end
end
