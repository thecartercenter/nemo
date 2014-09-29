class Report::AnswerTallyReport < Report::TallyReport

  # Called when related OptionSet (and OptionSetChoice) are destroyed.
  # Destroys self if there are no option sets left.
  def option_set_destroyed
    destroy if option_sets.empty?
  end

  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h[:option_set_choices_attributes] = option_set_choices
    h
  end

  protected

    def prep_query(rel)
      joins = []

      # add tally to select
      rel = rel.select("COUNT(responses.id) AS tally")

      # add question grouping
      expr = question_labels == "title" ? "questions.name_translations" : "questions.code"
      rel = rel.select("#{expr} AS pri_name, #{expr} AS pri_value, 'text' AS pri_type")
      joins << :questions
      rel = rel.group(expr)

      # add answer grouping
      # if we have an option set, we don't use calculation objects
      unless option_sets.empty?
        # add name expression
        expr = "IFNULL(ao.name_translations, co.name_translations)"
        rel = rel.select("#{expr} AS sec_name")
        rel = rel.group(expr)

        # add value expression
        expr = "IFNULL(ans_opt_nodes.rank, ch_opt_nodes.rank)"
        rel = rel.select("#{expr} AS sec_value")
        rel = rel.group(expr)
        rel = rel.where("option_sets.id" => option_sets.collect{|os| os.id})

        # type is just text
        rel = rel.select("'text' AS sec_type")

        # we order first by question name/code and then by option rank, which is the same as sec_value
        rel = rel.order("pri_value, sec_value")

      # we don't have an option set, so expect calculation objects
      else
        raise Report::ReportError.new("no calculations") if calculations.empty?

        # get expression fragments
        # this could be optimized by grouping name/value/sort for each calculation type, but i don't think it will impact performance much
        name_exprs = calculations.collect{|c| c.name_expr}
        value_exprs = calculations.collect{|c| c.value_expr}
        sort_exprs = calculations.collect{|c| c.sort_expr}
        where_exprs = calculations.collect{|c| c.where_expr}

        # build full expressions
        name_expr_sql = build_nested_if(name_exprs, where_exprs)
        value_expr_sql = build_nested_if(value_exprs, where_exprs)
        sort_expr_sql = build_nested_if(sort_exprs, where_exprs)

        # add the selects and groups
        rel = rel.select("#{name_expr_sql} AS sec_name, #{value_expr_sql} AS sec_value, #{sort_expr_sql} AS sec_sort_value, 'text' AS sec_type")
        rel = rel.group(name_expr_sql).group(value_expr_sql).group(sort_expr_sql)

        # add the unified wheres
        rel = rel.where("(" + where_exprs.collect{|e| e.sql}.join(" OR ") + ")")

        # sort by sort expression
        rel = rel.order("option_sets.name, sec_sort_value, pri_value")
      end

      # add joins to relation
      joins << :options << :choices << :option_sets
      rel = add_joins_to_relation(rel, joins)

      # apply filter
      rel = apply_filter(rel)

      rel = filter_non_top_level_answers(rel)

      return rel
    end

    def header_title(which)
      I18n.t("activerecord.models." + (which == :row ? "question" : "answer"), :count => 2)
    end

    def has_grouping(which)
      return true
    end

  private
    # builds a nested SQL IF statement of the form IF(a, x, IF(b, y, IF(c, z, ...)))
    def build_nested_if(exprs, conds)
      if exprs.size == 1
        return exprs.first.sql
      else
        rest = build_nested_if(exprs[1..-1], conds[1..-1])
        "IF(#{conds.first.sql}, #{exprs.first.sql}, #{rest})"
      end
    end

    def filter_non_top_level_answers(rel)
      rel.where('answers.rank IS NULL OR answers.rank = 1')
    end
end
