# frozen_string_literal: true

class Search::LexToken
  attr_reader :kind, :content, :fragment
  attr_accessor :parent

  # array of lex token kinds, in the order by which they should be searched
  EQUAL = {name: :equal, pattern: "="}.freeze
  KINDS = [
    {name: :colon, pattern: ":", sql: "="},
    EQUAL,
    {name: :gteq, pattern: ">="},
    {name: :lteq, pattern: "<="},
    {name: :gt, pattern: ">"},
    {name: :lt, pattern: "<"},
    {name: :noteq, pattern: "!="},
    {name: :lparen, pattern: "("},
    {name: :rparen, pattern: ")"},
    {name: :comma, pattern: ","},
    {name: :or, pattern: /OR|\|/},
    {name: :string, pattern: /"((?:[^"\\]|\\.)*)"/, sub_idx: 1, unescape_dbl_quotes: true},
    {name: :chunk, pattern: /[^\s:=<>!,)]+/}
  ].freeze

  def initialize(defn, content = "", fragment = "")
    @kind = defn[:name]
    @content = content
    @fragment = fragment
    @sql = (defn[:sql] || @content || "")
  end

  def is?(kind)
    @kind == kind
  end

  def to_s
    "#{@kind}(#{@content})"
  end

  def to_sql
    @sql
  end

  def to_s_indented(level = 0)
    ("  " * level) + to_s
  end
end
