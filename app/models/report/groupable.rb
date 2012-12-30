module Report::Groupable
  module ClassMethods
  end

  def self.included(base)
    # ruby idiom to activate class methods
    base.extend(ClassMethods)
    
    # add scope
    base.class_eval do
      attr_accessible :calculations_attributes
      has_many(:calculations, :class_name => "Report::Calculation", :foreign_key => "report_report_id")
      accepts_nested_attributes_for(:calculations, :allow_destroy => true)
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
    @pri_grouping ||= grouping(1)
  end

  def sec_grouping
    @sec_grouping ||= grouping(2)
  end
  
  def grouping(rank)
    c = calculations.find_by_rank(rank)
    c.nil? ? nil : Report::Grouping.new(c, [:primary, :secondary][rank-1])
  end
  
  def has_grouping(which)
    grouping = which == :row ? pri_grouping : sec_grouping
    !grouping.nil?
  end
  
  def header_title(which)
    grouping = which == :row ? pri_grouping : sec_grouping
    grouping ? grouping.header_title : nil
  end
  
  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h
  end
end