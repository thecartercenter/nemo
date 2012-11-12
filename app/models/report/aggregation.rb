class Report::Aggregation

  attr_accessor :name, :expr_template, :accepts
  
  def self.get(name)
    @@AGGREGATIONS[name.to_sym]
  end
  
  def expr(sub_expr)
    expr_template.gsub("?", sub_expr)
  end
  
  # raises a ReportError if input type is not compatible with this aggregation
  def output_data_type(input_type)
    # check for invalid combinations
    raise Report::ReportError.new("The #{name} aggregation does not accept data of type #{input_type}.") unless accepts.include?(input_type.to_s)
    
    if name == :average
      "decimal"
    else
      input_type
    end
  end
  
  private 
    def initialize(params)
      params.each{|k,v| self.send("#{k}=", v)}
    end
    
    @@AGGREGATIONS = {
      :average => new(
        :name => :average,
        :expr_template => "AVG(?)",
        :accepts => %w(integer decimal)
      ),
      :sum => new(
        :name => :sum,
        :expr_template => "SUM(?)",
        :accepts => %w(integer decimal)
      ),
      :minimum => new(
        :name => :minimum,
        :expr_template => "MIN(?)",
        :accepts => %w(integer decimal text long_text select_one select_multiple datetime date time)
      ),
      :maximum => new(
        :name => :maximum,
        :expr_template => "MAX(?)",
        :accepts => %w(integer decimal text long_text select_one select_multiple datetime date time)
      )
    }
end