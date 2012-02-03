class Report::ByAttribGrouping < Report::Grouping
  belongs_to(:attrib, :class_name => "Report::GroupingAttribute")
  
  def self.select_options
    Report::GroupingAttribute.all.collect{|g| ["#{g.name}", "by_attrib_#{g.id}"]}
  end
  
  # applies this grouping to the given relation
  def apply(rel)
    rel = rel.select("#{attrib.code} as `#{attrib.name}`").
      joins(Report::Join.list_to_sql(attrib.join_tables.split(","))).group(attrib.code)
  end
  
  def col_name
    attrib.name
  end
  
  def form_choice
    "by_attrib_#{attrib_id}"
  end
  
  def assoc_id=(id)
    self.attrib_id = id
  end
end