class Report::ByAttribGrouping < Report::Grouping
  belongs_to(:attrib, :class_name => "Report::GroupingAttribute")
  
  def self.select_options
    Report::GroupingAttribute.all.collect{|g| ["#{g.name}", "by_attrib_#{g.id}"]}
  end
  
  def self.select_group_name; "Attributes"; end
  
  # applies this grouping to the given relation
  def apply(rel)
    rel = rel.select("#{attrib.code} as `#{col_name}`")
    rel = rel.joins(Report::Join.list_to_sql(attrib.join_tables.split(","))) if attrib.join_tables
    rel = rel.group(attrib.code)
  end
  
  def col_name
    "attrib_#{attrib.name.gsub(' ','').underscore}"
  end
  
  def form_choice
    "by_attrib_#{attrib_id}"
  end
  
  def assoc_id=(id)
    self.attrib_id = id
  end
  
  def attrib_is_date?
    attrib.name =~ /^Date/
  end
  
  def to_s
    attrib.name
  end
  
  def process_results(results)
    # if this is a date grouping, change the date objects into nice date strings
    if attrib_is_date?
      results.each{|r| r[col_name] = r[col_name].to_s.gsub(" 00:00:00", "")}
    end
    results
  end
end