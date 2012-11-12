class Report::SingleFieldAggregatedReport < Report::AggregatedReport
  include Report::Groupable
  
  has_one(:calculation, :class_name => "Report::Calculation", :foreign_key => "report_report_id", :dependent => :destroy, :autosave => true)
  attr_accessible(:calculation, :calculation_attributes)
  
  protected

    def prep_relation(rel)
      joins = []
    
      # add the aggregation
      agg_expr = aggregation.expr(calculation.value_expr)
      where_expr = calculation.where_expr
      rel = rel.select("#{agg_expr} AS agg")
      rel = rel.where(where_expr)
      joins += calculation.joins
    
      # add filter
      rel = filter.apply(rel) unless filter.nil?
    
      # add groupings
      rel = apply_groupings(rel)
    
      # add joins
      rel = add_joins_to_relation(rel, joins)
    end
  
    # extracts and casts the result value from the given result row
    def get_result_value(row)
      Report::Formatter.format(row["agg"], aggregation.output_data_type(calculation.output_data_type))
    end
end