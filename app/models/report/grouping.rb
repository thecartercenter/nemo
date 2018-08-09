class Report::Grouping

  def initialize(calculation, rank)
    @calculation = calculation
    @rank = rank
  end

  def apply(rel)
    prefix = @rank.to_s[0,3]

    # get fragments
    @calculation.table_prefix = prefix
    name_expr = @calculation.name_expr
    value_expr = @calculation.value_expr
    where_expr = @calculation.where_expr
    type_expr = @calculation.data_type_expr
    sort_expr = @calculation.sort_expr

    # add select, where, and group
    rel = rel.select("#{name_expr.sql} AS #{prefix}_name")
    rel = rel.select("#{value_expr.sql} AS #{prefix}_value")
    rel = rel.select("#{type_expr.sql} AS #{prefix}_type")
    rel = rel.where(where_expr.sql)
    rel = rel.group(name_expr.sql)
    rel = rel.group(value_expr.sql)

    # add order
    rel = rel.order(sort_expr.sql) if sort_expr

    # add joins, with label as prefix
    rel = rel.joins(Results::Join.list_to_sql(@calculation.joins, prefix: prefix))

    # Filter for top-level answers only if applicable.
    rel = filter_non_top_level_answers(rel, prefix) if @calculation.question1

    return rel
  end

  def filter_non_top_level_answers(rel, prefix)
    return rel unless @calculation.joins.include?(:options)
    rel.where("#{prefix}_ans_opt_nodes.ancestry_depth IS NULL OR #{prefix}_ans_opt_nodes.ancestry_depth <= 1")
  end

  def header_title
    @calculation.header_title
  end
end
