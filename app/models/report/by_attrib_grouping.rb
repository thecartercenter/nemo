class Report::ByAttribGrouping < Report::Grouping
  belongs_to(:attrib, :class_name => "Report::ResponseAttribute")
  
  # applies this grouping to the given relation
  def apply(rel)
    attrib.apply(rel, :group => true)
  end

  def sql_col_name
    attrib.sql_col_name
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
end