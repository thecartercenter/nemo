# frozen_string_literal: true

class Search::Token
  attr_accessor :children
  attr_reader :kind

  def initialize(search, kind, parent)
    @search = search
    @kind = kind
    @parent = parent
  end

  def to_s_indented(level = 0)
    ("  " * level) + "#{kind}\n" + children.collect { |c| c.to_s_indented(level + 1) }.join("\n")
  end

  # returns an sql string
  def to_sql
    @sql ||=
      case kind
      when :query
        # expressions should be ANDed together
        children.map(&:to_sql).join(" AND ")

      when :unqualified_expression
        eq = Search::LexToken.new(Search::LexToken::EQUAL, "=")
        "(" + default_qualifiers.map { |q| comparison(q, eq, children[0]) }.join(" OR ") + ")"

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

  def is?(kind)
    @kind == kind
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
    expr.op = op

    # ensure valid operator
    raise_error_with_qualifier("invalid_op", qual_name, op: op.content) unless qual.op_valid?(op.to_sql)

    # expand rhs into leaves and iterate
    previous = nil
    sql = ""
    expr.values = ""
    leaves = rhs_or_values.expand
    expr.leaves = leaves
    leaves.each do |lex_tok|
      # if this is a value token descendant
      if lex_tok.parent.is?(:value)

        # if the previous token was also a value token, need to insert the implicit AND
        if previous&.parent&.is?(:value)
          sql += " AND "
          expr.values += " "
        end

        sql += if qual.has_more_than_one_column?
                 comparisons_for_all_columns(qual, op, lex_tok)
               else
                 comparison_fragment(qual, qual.col, op, lex_tok)
               end

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
      "(#{qual.col} IN (####{@search.expressions.size - 1}###))"
    else
      if op.kind == :noteq
        "NOT(#{sql})"
      else
        sql
      end
    end
  end

  def comparisons_for_all_columns(qualifier, op, lex_tok)
    qualifier.col.map { |c| comparison_fragment(qualifier, c, op, lex_tok) }.join(" OR ")
  end

  # generates an sql where clause fragment for a comparison with the
  # given qualifier, operator, and value token
  def comparison_fragment(qualifier, column, op, value_token)
    # get the sql representations
    value_sql = value_token.to_sql
    op_sql = op.to_sql
    # Since we are negating the entire expression, treat != as = within the comparison
    op_sql = "=" if op.kind == :noteq

    # Transform the value if qualifier has transformer.
    value_sql = qualifier.preprocessor.call(value_sql) if qualifier.preprocessor

    # Need to use this or negations don't work as expected.
    and_not_null = op.kind == :noteq ? " AND #{column} IS NOT NULL" : ""

    if qualifier.type == :date
      begin
        time = Time.zone.parse(value_sql)
        value_sql = time.to_s(:std_datetime)
      rescue ArgumentError
        raise_error_with_qualifier("invalid_date", qualifier, value: value_sql)
      end
    end

    # if rhs is [blank], act accordingly
    inner =
      if [I18n.locale, :en].map { |l| "[" + I18n.t("search.blank", locale: l) + "]" }.include?(value_sql)
        op_sql = "IS"
        "#{column} #{op_sql} NULL"

      elsif qualifier.type == :translated
        sanitize("#{column} ->> ? ILIKE ?#{and_not_null}", I18n.locale, "%#{value_sql}%")

      elsif qualifier.type == :boolean
        truthy = ["1", I18n.t("common._yes").downcase]
        falsy = ["0", I18n.t("common._no").downcase]

        input_value = value_sql.downcase
        bool_value = if truthy.include?(input_value)
                       "t"
                     elsif falsy.include?(input_value)
                       "f"
                     else
                       raise_error_with_qualifier("boolean_error", qualifier.name)
                     end

        sanitize("#{column} = ?", bool_value)

      # if partial matches are allowed, change to LIKE
      elsif qualifier.type == :text
        op_sql = "ILIKE"
        sanitize("#{column} #{op_sql} ?#{and_not_null}", "%#{value_sql}%")
      else
        sanitize("#{column} #{op_sql} ?#{and_not_null}", value_sql)
      end

    "(#{inner})"
  end

  # looks up the default qualifiers
  # raises an error if there are none
  def default_qualifiers
    @search.qualifiers.select(&:default?).tap do |dq|
      raise Search::ParseError, I18n.t("search.must_use_qualifier") if dq.empty?
    end
  end

  def sanitize(*args)
    SqlRunner.instance.sanitize(*args)
  end

  # expands the current token into its component lextokens (leaf nodes)
  def expand
    children.map { |c| c.is_a?(Search::LexToken) ? c : c.expand }.flatten
  end

  def raise_error_with_qualifier(err_name, qual, params = {})
    raise Search::ParseError, I18n.t("search.#{err_name}", params.merge(qualifier: qual))
  end
end
