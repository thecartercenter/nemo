class Search::Token
  attr_accessor :children
  attr_reader :kind

  def initialize(search, kind, parent)
    @search = search
    @kind = kind
    @parent = parent
  end

  def to_s_indented(level = 0)
    ("  " * level) + "#{kind}\n" + children.collect{|c| c.to_s_indented(level + 1)}.join("\n")
  end

  # returns an sql string
  def to_sql
    @sql ||= case kind

    when :query
      # expressions should be ANDed together
      children.map(&:to_sql).join(" AND ")

    when :unqualified_expression
      eq = Search::LexToken.new(Search::LexToken::EQUAL, "=")
      "(" + default_qualifiers.map{ |q| comparison(q, eq, children[0]) }.join(' OR ') + ")"

    when :qualified_expression
      # children[2] will be an :rhs token
      "(" + comparison(children[0], children[1], children[2]) + ")"

    when :values
      # if first form, 'and' is implicit
      if children[1] && !children[1].is?(:or)
        "#{children[0].to_sql} AND #{children[1].to_sql}"
      else
        children.map(&:to_sql).join
      end

    else
      children[0].to_sql
    end
  end

  protected
    # generates an sql fragment for a comparison
    # qual - a LexToken representing a search qualifier, or a Search::Qualifier object
    # op - a LexToken representing an operator. these should be checked for compatibility with Qualifier
    # rhs_or_values - an :rhs or :values Token
    def comparison(qual, op, rhs_or_values)
      # make an expression object for this comparison
      expr = Search::Expression.new

      # if qual was given as a lex token, save its original content as we might need it later
      # then lookup the qualifier
      if qual.is_a?(Search::LexToken)
        expr.qualifier_text = qual.content
        qual = Search::Qualifier.find_in_set(@search.qualifiers, qual.content)
      end

      qual_name = expr.qualifier_text || I18n.t("search_qualifiers.#{qual.name}")

      expr.qualifier = qual

      # ensure valid operator
      raise_error_with_qualifier('invalid_op', qual_name, :op => op.content) unless qual.op_valid?(op.to_sql)

      # expand rhs into leaves and iterate
      previous = nil
      sql = ""
      expr.values = ""
      leaves = rhs_or_values.expand
      leaves.each do |lex_tok|

        # if this is a value token descendant
        if lex_tok.parent.is?(:value)

          # if the previous token was also a value token, need to insert the implicit AND (if allowed)
          if previous && previous.parent.is?(:value)
            if qual.and_allowed?
              sql += " AND "
              expr.values += " "
            else
              raise_error_with_qualifier('multiple_terms_not_allowed', qual_name)
            end
          end

          # insert the comparison itself
          sql += comparison_fragment(qual, op, lex_tok)
          expr.values += lex_tok.is?(:string) ? "\"#{lex_tok.content}\"" : lex_tok.content

        # else, if this is an 'OR', insert that
        elsif lex_tok.is?(:or)
          sql += " OR "
          expr.values += " | "
        end

        previous = lex_tok
      end

      @search.expressions << expr

      if qual.type == :indexed
        "(#{qual.col} IN (####{@search.expressions.size-1}###))"
      else
        sql
      end
    end

    # generates an sql where clause fragment for a comparison with the given qualifier, operator, and value token
    def comparison_fragment(qual, op, value_token)
      # get the sql representations
      value_sql = value_token.to_sql
      op_sql = op.to_sql

      # Transform the value if qualifier has transformer.
      value_sql = qual.preprocessor.call(value_sql) if qual.preprocessor

      # if rhs is [blank], act accordingly
      inner = if [I18n.locale, :en].map{|l| '[' + I18n.t('search.blank', :locale => l) + ']'}.include?(value_sql)
        op_sql = (op_sql == "=" ? "IS" : "IS NOT")
        "#{qual.col} #{op_sql} NULL"

      # if translated qualifier, use special expression
      elsif qual.type == :translated
        op_sql = op_sql == "=" ? "RLIKE" : "NOT RLIKE"
        # Sanitize first with special markers, then add the enclosing syntax for matching the RLIKE.
        sanitize("#{qual.col} #{op_sql} ?", "%%%1#{value_sql}%%%2").tap do |sql|
          sql.gsub!('%%%1', %{"#{I18n.locale}":"([^"\\]|\\\\\\\\.)*})
          sql.gsub!('%%%2', %{([^"\\]|\\\\\\\\.)*"})
        end

      # if partial matches are allowed, change to LIKE
      elsif qual.type == :text
        op_sql = op_sql == "=" ? "LIKE" : "NOT LIKE"
        sanitize("#{qual.col} #{op_sql} ?", "%#{value_sql}%")

      else
        sanitize("#{qual.col} #{op_sql} ?", value_sql)
      end

      "(#{inner})"
    end

    # looks up the default qualifiers
    # raises an error if there are none
    def default_qualifiers
      @search.qualifiers.select(&:default?).tap do |dq|
        raise Search::ParseError.new(I18n.t("search.must_use_qualifier")) if dq.empty?
      end
    end

    def is?(kind)
      @kind == kind
    end

    def sanitize(*args)
      ActiveRecord::Base.__send__(:sanitize_sql, args, '')
    end

    # expands the current token into its component lextokens (leaf nodes)
    def expand
      children.map{|c| c.is_a?(Search::LexToken) ? c : c.expand}.flatten
    end

    def raise_error_with_qualifier(err_name, qual, params = {})
      raise Search::ParseError.new(I18n.t("search.#{err_name}", params.merge(:qualifier => qual)))
    end
end
