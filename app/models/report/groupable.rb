module Report::Groupable
  module ClassMethods
  end

  def self.included(base)
    # ruby idiom to activate class methods
    base.extend(ClassMethods)
    
    # add scope
    base.class_eval do
      attr_accessible :pri_group_by, :sec_group_by, :pri_group_by_attributes, :sec_group_by_attributes
      belongs_to(:pri_group_by, :class_name => "Report::Calculation")
      belongs_to(:sec_group_by, :class_name => "Report::Calculation")
    end
  end
  
  # applys both groupings
  def apply_groupings(rel, options = {})
    raise Report::ReportError.new("Primary groupings are not allowed for this report type") if pri_grouping && options[:secondary_only]
    rel = pri_grouping.apply(rel) if pri_grouping
    rel = sec_grouping.apply(rel) if sec_grouping
    return rel
  end
  
  def pri_grouping
    @pri_grouping ||= (pri_group_by ? Report::Grouping.new(pri_group_by, :primary) : nil)
  end

  def sec_grouping
    @sec_grouping ||= (sec_group_by ? Report::Grouping.new(sec_group_by, :secondary) : nil)
  end
  
  def header_title(which)
    grouping = which == :row ? pri_grouping : sec_grouping
    grouping ? grouping.header_title : ""
  end
end