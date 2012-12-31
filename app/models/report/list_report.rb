class Report::ListReport < Report::Report
  
  has_many(:calculations, :class_name => "Report::Calculation", :foreign_key => "report_report_id", :order => "rank", :dependent => :destroy, :autosave => true)
  accepts_nested_attributes_for(:calculations, :allow_destroy => true)
  
  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h
  end

  protected
  
    def prep_relation(rel)
      joins = []
      
      # add each calculation
      calculations.each_with_index do |c, idx|
        # if calculation is question type, we need to add joins with a prefix
        if c.question1
          prefix = "#{idx}"
          c.table_prefix = prefix
          rel = rel.joins(Report::Join.list_to_sql(c.joins, prefix))
        else
          rel = rel.joins(Report::Join.list_to_sql(c.joins))
        end
        rel = rel.select("#{c.name_expr} AS #{idx}_name, #{c.value_expr} AS #{idx}_value, #{c.data_type_expr} AS #{idx}_type") 
        rel = rel.where(c.where_expr)
      end
    
      # apply filter
      rel = filter.apply(rel) unless filter.nil?
      
      return rel
    end
    
    def header_title(which)
      nil
    end
    
    def get_row_header
      nil
    end
  
    def get_col_header
      hashes = []
      calculations.each_with_index do |c, idx|
        hashes << {:name => c.header_title, :key => idx}
      end
      Report::Header.new(:title => nil, :cells => hashes)
    end
    
    # processes a row from the db_result by adding the contained data to the result
    def extract_data_from_row(db_row, db_row_idx)
      calculations.each_with_index do |c, idx|
        col_idx = @header_set[:col].find_key_idx(idx) or raise Report::ReportError.new("Couldn't find matching header for calculation #{idx}.")
        @data.set_cell(db_row_idx, col_idx, Report::Formatter.format(db_row["#{idx}_name"], db_row["#{idx}_type"], :cell))
      end 
    end
  
    # totaling is not appropriate
    def can_total?
      return false
    end
    
    def blank_data_table(db_result)
      # one row per result row
      db_result.rows.collect{Array.new(@header_set[:col].size)}
    end
     
    def remove_blank_rows
      # remove any blank rows from the data; don't have to worry about row headers as there are none
      (@data.rows.size-1).downto(0) do |i|
        @data.rows.delete_at(i) if @data.empty_row?(i)
      end
    end
end
