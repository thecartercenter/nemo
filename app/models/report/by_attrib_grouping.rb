class Report::ByAttribGrouping < Report::Grouping
  # applies this grouping to the given relation
  def apply(rel)
    rel = rel.select("#{code} as `#{name}`").joins(Report::Join.list_to_sql(join_tables.split(","))).group(code)
  end
  
  def col_name
    name
  end
end