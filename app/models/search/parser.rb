# frozen_string_literal: true

class Search::Parser
  attr_reader :sql

  # GRAMMAR
  # query ::= expression query | expression
  # expression ::= qualified-expression | unqualified-expression
  # unqualified-expression ::= values
  # qualified-expression ::= CHUNK comp-op rhs
  # rhs ::= value | "(" values ")"
  # values ::= value values | value or-op values | value
  # value ::= CHUNK | STRING
  # comp-op ::= "=" | ":" | "<" | ">" | "<=" | ">=" | "!="
  # or ::= "|" | "OR"

  COMP_OP = %i[colon equal lt gt lteq gteq noteq].freeze

  def initialize(attribs)
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  def parse
    if @search.str.blank?
      @sql = "true"
    else
      @lexer = Search::Lexer.new(@search.str)
      @lexer.lex
      @query = take(nil, :query)
      # puts "PARSE TREE\n" + @query.to_s_indented
      @sql = @query.to_sql
    end
  end

  private

  # parses a token of the specified kind out of the lexical tokens
  # returns an array of Tokens and/or LexTokens corresponding to the matching grammar rule
  def take(parent, kind)
    # puts "PARENT #{parent.try(:kind)} TAKING #{kind} FROM #{@lexer.tokens[0].fragment} " \
    #   "NEXT IS #{@lexer.tokens[1..2].map(&:kind).join(',')}"
    token = Search::Token.new(@search, kind, parent)

    token.children =
      case kind
      when :query
        [take(token, :expression)] + (next_is?(:eot) ? [] : [take(token, :query)])

      when :expression
        raise Search::ParseError, I18n.t("search.or_not_allowed_between") if next_is?(:or)
        if next_is?(:chunk) && next2_is?(*COMP_OP)
          [take(token, :qualified_expression)]
        else
          [take(token, :unqualified_expression)]
        end

      when :unqualified_expression
        [take(token, :values)]

      when :qualified_expression
        [take_terminal(token, :chunk), take_terminal(token, *COMP_OP), take(token, :rhs)]

      when :rhs
        if next_is?(:lparen)
          [take_terminal(token, :lparen), take(token, :values), take_terminal(token, :rparen)]
        else
          [take(token, :value)]
        end

      when :values
        [take(token, :value)] + if next_is?(:eot, :rparen) || next2_is?(*COMP_OP)
                                  []
                                elsif next_is?(:or)
                                  [take_terminal(token, :or), take(token, :values)]
                                else
                                  [take(token, :values)]
                                end

      when :value
        [take_terminal(token, :chunk, :string)]
      end

    token
  end

  def take_terminal(parent, *options)
    if next_is?(*options)
      # set parent for lex token and return
      lex_token = @lexer.tokens.shift
      lex_token.parent = parent
      lex_token
    else
      near = @lexer.tokens[0].fragment
      raise Search::ParseError, I18n.t(near.empty? ? "search.unexpected_end" : "search.unexpected", str: near)
    end
  end

  def next_is?(*options)
    options.include?(nil) || options.include?(@lexer.tokens[0].kind)
  end

  def next2_is?(*options)
    options.include?(nil) || @lexer.tokens[1] && options.include?(@lexer.tokens[1].kind)
  end
end
