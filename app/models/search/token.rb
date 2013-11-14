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
    when :comp_op, :bin_bool_op, :term
      child(0).to_sql
    when :target
      # first form
      if child(0).is?(:lparen)
        child(1).to_sql
      # other forms
      else
        child(0).to_sql
      end
    when :qual_term
      # child(2) will be a target_set token
      "(" + comparison(child(0), child(1).child(0), child(2)) + ")"
    when :unqual_term
      "(" + default_quals.collect{|q| comparison(q, EQUAL_TOKEN, child(0))}.join(" OR ") + ")"
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
    when :chunks
      child(0).to_sql + (child(1) ? ' ' + child(1).to_sql : '')
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
    # qual - either a Search::Qualifier or a LexToken that needs to be converted into a Qualifier
    # op - a LexToken representing an operator. these should be checked for compatibility with Qualifier
    # rhs - a target or target_set token
    def comparison(qual, op, rhs)
      # if qual was given as a lex token, save its original content as we might need it later
      # then lookup the qualifier
      if qual.is_a?(Search::LexToken)
        qual_text = qual.content
        qual = lookup_qualifier(qual.content)
      else
        qual_text = nil
      end

      # ensure valid operator
      raise Search::ParseError.new(I18n.t("search.invalid_op", :op => op.content, :qualifier => qual.name)) unless qual.op_valid?(op.to_sql)
      
      # first expand the rhs token into targets
      fragments = rhs.targets.map do |target_token|

        # get the sql representation of the target_token
        target_sql = target_token.to_sql

        # sanitize by default
        sanitize_rhs = true
        
        # perform substitution if specified
        target_sql = qual.subst[target_sql] || target_sql

        # get the op sql
        op_sql = op.to_sql
        
        # if the operator is equal/not-equal
        if ["=", "!="].include?(op_sql)
          # if rhs is [null], act accordingly
          if target_sql =~ /\[null\]/i
            op_sql = (op_sql == "=" ? "IS" : "IS NOT")
            target_sql = "NULL"
            sanitize_rhs = false

          # if partial matches are allowed, change to LIKE
          elsif qual.partials?
            op_sql = op_sql == "=" ? "LIKE" : "NOT LIKE"
            target_sql = "%#{target_sql}%"
          end
        end
        
        # save the associations needed for this comparison
        @assoc = (@assoc || []) + qual.assoc
          
        # generate the string
        if qual.fulltext?
          # wrap in double quotes, to achieve exact phrase match, if target is a quoted string
          target_sql = "\"#{target_sql}\"" if target_token.child(0).is?(:string)

          sanitize("MATCH (#{qual.col}) AGAINST (? IN BOOLEAN MODE)", target_sql)
        else
          sanitize_rhs ? sanitize("#{qual.col} #{op_sql} ?", target_sql) : sanitize("#{qual.col} #{op_sql} #{target_sql}")
        end
      end

      # now OR the fragments together
      condition = fragments.join(' OR ')

      # if there was an extra condition requested, add it
      if qual.extra_condition
        # first get the match data for the qualifier text if available
        md = qual.regexp? ? qual.name.match(qual_text) : nil

        # now run the extra condition lambda, passing the match data
        extra_cond_args = qual.extra_condition.call(md)

        # now sanitize
        extra_cond_sql = sanitize(*extra_cond_args)

        # now build the full string
        condition = "(#{condition}) AND (#{extra_cond_sql})"
      end

      condition
    end
    
    # looks up all the default qualifiers for the Search's class
    # raises an error if there are none
    def default_quals
      dq = @search.qualifiers.select{|q| q.default?}
      raise Search::ParseError.new(I18n.t("search.must_use_qualifier")) if dq.empty?
      dq
    end
    
    # looks up the qualifier for the given chunk, or raises an error
    def lookup_qualifier(chunk)
      qualifier = nil
      
      # get the qualifier translations for current locale and reverse them
      trans = I18n.t("search_qualifiers").invert

      # also add the qualifier translations for english if the current locale is not english
      trans.merge!(I18n.t("search_qualifiers", :locale => :en).invert) unless I18n.locale == :en
      
      # add a bunch of entries with accents removed
      normalized = {}
      trans.each do |k,v|
        k_normalized = ActiveSupport::Inflector.transliterate(k)
        normalized[k_normalized] = v if k != k_normalized
      end
      trans.merge!(normalized)
      
      # try looking up the chunk. this should now work even the user didn't put in the accents
      qualifier_name = trans[chunk].to_s

      # if qualifier_name is not nil, try to find the qualifier object
      unless qualifier_name.nil?
        qualifier = @search.qualifiers.detect{|q| q.name == qualifier_name}
      end

      # if we haven't found a matching qualifier yet, look for any regexp style ones
      if qualifier.nil?
        @search.qualifiers.find_all{|q| q.regexp?}.each do |q|
          # check against the regular expression and then against the validator (if defined)
          if q.matches(chunk)
            qualifier = q
            break
          end
        end
      end
      
      raise Search::ParseError.new(I18n.t("search.invalid_qualifier", :chunk => chunk)) if qualifier.nil?
      
      qualifier
    end
    
    def child(num); @children[num]; end
    def is?(kind); @kind == kind; end

    def sanitize(*args)
      ActiveRecord::Base.__send__(:sanitize_sql, args, '')
    end

    # gets all :target tokens represented by this token
    # if this token is a :target token, just returns this token wrapped in an array
    # if this token is a :target_set token, expands to find all :target tokens and returns
    # else raises error
    def targets
      if @kind == :target
        [self]
      elsif @kind == :target_set
        [child(0)] + (child(1) ? child(2).targets : [])
      else
        raise "can't call targets on :#{@kind} token"
      end
    end
end
