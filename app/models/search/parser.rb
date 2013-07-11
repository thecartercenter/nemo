class Search::Parser
  
  # GRAMMAR
  # query ::= "(" query ")" | term bin-bool-op query | term query | term
  # term ::= qual-term | unqual-term
  # unqual-term ::= target
  # qual-term ::= CHUNK comp-op target-set
  # bin-bool-op ::= "and" | "or"
  # comp-op ::= "=" | ":" | "<" | ">" | "<=" | ">=" | "!=" | "<>"
  # target-set ::= target "," target-set | target
  # target ::= STRING | CHUNK
  
  COMP_OP = [:colon, :equal, :lt, :gt, :lteq, :gteq, :gtlt, :noteq]
  BIN_BOOL_OP = [:and, :or]
  
  def initialize(search)
    @search = search
    @str = @search.str
  end
  
  def parse
    unless @str.blank?
      @lexer = Search::Lexer.new(@str)
      @lexer.lex
      @query = take(:query)
    end
  end
  
  def sql
    # default sql is simply "1" (which matches all records)
    @query ? @query.to_sql : "1"
  end
  
  def assoc
    @query ? @query.assoc : []
  end
  
  private
    def take(kind)
      #puts "TAKING #{kind} FROM #{@lexer.tokens[0].fragment}"
      Search::Token.new(@search, kind, 
        case kind
        when :query
          if next_is(:lparen)
            [take_terminal(:lparen), take(:query), take_terminal(:rparen)]
          else
            [take(:term)] + 
              if next_is(*BIN_BOOL_OP)
                [take(:bin_bool_op), take(:query)]
              elsif !next_is(:eot,:rparen)
                [take(:query)]
              else
                []
              end
          end
          
        when :term
          (next_is(:chunk) && next2_is(*COMP_OP)) ? take(:qual_term) : take(:unqual_term)
      
        when :unqual_term
          take(:target)
        
        when :qual_term
          [take_terminal(:chunk), take(:comp_op), take(:target_set)]
      
        when :bin_bool_op
          take_terminal(*BIN_BOOL_OP)
      
        when :comp_op
          take_terminal(*COMP_OP)
      
        when :target_set
          [take(:target)] + (next_is(:comma) ? [take_terminal(:comma), take(:target_set)] : [])
        
        when :target
          take_terminal(:chunk, :string)
        end
      )
    end
  
    def take_terminal(*options)
      if next_is(*options)
        @lexer.tokens.shift
      else
        expected = options.collect{|o| o.to_s.upcase}.compact.join("' #{I18n.t('common.or')} '")
        near = @lexer.tokens[0].fragment
        near = near.empty? ? I18n.("searches.at_end_of_query") : "#{I18n.t('common.near').downcase} '#{near}'"
        raise Search::ParseError.new("#{I18n.t('search.expected')} '#{expected}' #{near}")
      end 
    end
  
    def next_is(*options)
      options.include?(nil) || options.include?(@lexer.tokens[0].kind)
    end
  
    def next2_is(*options)
      options.include?(nil) || @lexer.tokens[1] && options.include?(@lexer.tokens[1].kind)
    end
end