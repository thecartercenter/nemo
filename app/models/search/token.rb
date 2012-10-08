class Search::Token
  EQUAL_TOKEN = Search::LexToken.new(Search::LexToken::EQUAL, "=")
  
  def initialize(search, kind, children)
    @search = search
    @kind = kind
    @children = children.is_a?(Array) ? children : [children]
  end

  def to_s_indented(level = 0)
    ("  " * level) + "#{@kind}\n" + @children.collect{|c| c.to_s_indented(level + 1)}.join("\n")
  end
  
  # returns either an sql string or an array of sql fragments, depending on the kind
  def to_sql
    @sql ||= case @kind
    when :target, :comp_op, :bin_bool_op, :term
      child(0).to_sql
    when :target_set
      # array of fragments, one per target
      [child(0).to_sql] + (child(1) ? child(2).to_sql : [])
    when :qual_term
      # child(2) will be an array (target_set)
      "(" + child(2).to_sql.collect{|sql| comparison(child(0), child(1).child(0), sql)}.join(" OR ") + ")"
    when :unqual_term
      "(" + default_quals.collect{|q| comparison(q, EQUAL_TOKEN, child(0).to_sql)}.join(" OR ") + ")"
    when :query
      # first form
      if child(0).is?(:lparen)
        @children.collect{|c| c.to_sql}.join
      # second form
      elsif child(1) && child(1).is?(:bin_bool_op)
        @children.collect{|c| c.to_sql}.join(" ")
      # third form
      elsif child(1) && child(1).is?(:query)
        child(0).to_sql + " AND " + child(1).to_sql
      # fourth form
      else
        child(0).to_sql
      end
    end
  end
  
  def assoc
    if @assoc.nil?
      # generate sql so that assoc array is populated
      to_sql
      # gather associations for all children
      @assoc = (@assoc || []) + @children.collect{|c| c.is_a?(Search::Token) ? c.assoc : []}.flatten
      # make sure there are no duplicate entries
      @assoc.uniq!
    end
    @assoc
  end
  
  protected
    # generates an sql fragment for a comparison
    # qual is either a Search::Qualifier or a LexToken that needs to be converted into a Qualifier
    # op is a LexToken representing an operator. these should be checked for compatibility with Qualifier
    # rhs is an sql fragment that serves as the right hand side of the comparison
    def comparison(qual, op, rhs)
      qual = lookup_qualifier(qual.content) if qual.is_a?(Search::LexToken)
      raise Search::ParseError.new("The operator '#{op.content}' is not valid for the qualifier '#{qual.name}'.") unless qual.op_valid?(op.to_sql)
      
      # sanitize by default
      sanitize_rhs = true
      
      # perform substitution if specified
      rhs = qual.subst[rhs] || rhs

      # get the op sql
      op_sql = op.to_sql
      
      # if the operator is equal/not-equal
      if ["=", "!="].include?(op_sql)
        # if rhs is [null], act accordingly
        if rhs =~ /\[null\]/i
          op_sql = (op_sql == "=" ? "IS" : "IS NOT")
          rhs = "NULL"
          sanitize_rhs = false
        # if partial matches are allowed, change to LIKE
        elsif qual.partials?
          op_sql = op_sql == "=" ? "LIKE" : "NOT LIKE"
          rhs = "%#{rhs}%"
        end
      end
      
      # save the associations needed for this comparison
      @assoc = (@assoc || []) + Array.wrap(qual.assoc)
        
      # generate the string
      sanitize_rhs ? sanitize("#{qual.col} #{op_sql} ?", rhs) : sanitize("#{qual.col} #{op_sql} #{rhs}")
    end
    
    # looks up all the default qualifiers for the Search's class
    # raises an error if there are none
    def default_quals
      dq = @search.klass.search_qualifiers.select{|q| q.default?}
      raise Search::ParseError.new("You must use a qualifier for all search terms") if dq.empty?
      dq
    end
    
    # looks up the qualifier for the given chunk, or raises an error
    def lookup_qualifier(chunk)
      @search.klass.search_qualifiers.find{|q| q.label == chunk} or raise Search::ParseError.new("'#{chunk}' is not a valid search qualifier")
    end
    
    def child(num); @children[num]; end
    def is?(kind); @kind == kind; end

    def sanitize(*args)
      ActiveRecord::Base.__send__(:sanitize_sql, args, '')
    end
end
