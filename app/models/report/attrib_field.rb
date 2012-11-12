# models response attributes that are not answers to questions (user, date, etc.)
class Report::AttribField < Report::Field
  
  attr_accessor :name, :name_expr_template, :value_expr_template, :data_type, :groupable
  
  def self.get(name)
    @@ATTRIBS[name.to_sym]
  end

  def name_expr(table_prefix)
    name_expr_template.gsub("__", table_prefix).gsub("_CURRENT_TIMEZONE_", Time.zone.mysql_name)
  end
  
  def value_expr(table_prefix)
    value_expr_template.gsub("__", table_prefix).gsub("_CURRENT_TIMEZONE_", Time.zone.mysql_name)
  end
  
  def where_expr(table_prefix)
    ""
  end
  
  def sort_expr(table_prefix)
    name_expr(table_prefix)
  end
  
  def joins
    @joins || []
  end
    
  private 
    def initialize(params)
      params.each{|k,v| self.send("#{k}=", v)}
    end
    
    def joins=(j)
      @joins = j
    end
    
    @@ATTRIBS = {
      :form => new(
        :name => :form,
        :name_expr_template => "__forms.name",
        :value_expr_template => "__forms.name",
        :joins => [:forms],
        :data_type => :text,
        :groupable => true),
      :form_type => new(
        :name => :form_type,
        :name_expr_template => "__form_types.name",
        :value_expr_template => "__form_types.name",
        :joins => [:form_types],
        :data_type => :text,
        :groupable => true),
      :submitter => new(
        :name => :submitter,
        :name_expr_template => "__users.name",
        :value_expr_template => "__users.name",
        :joins => [:users],
        :data_type => :text,
        :groupable => true),
      :source => new(
        :name => :source,
        :name_expr_template => "responses.source",
        :value_expr_template => "responses.source",
        :data_type => :text,
        :groupable => true),
      :time_submitted => new(
        :name => :time_submitted,
        :name_expr_template => "responses.created_at",
        :value_expr_template => "responses.created_at",
        :data_type => :datetime),
      :date_submitted => new(
        :name => :date_submitted,
        :name_expr_template => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '_CURRENT_TIMEZONE_'))",
        :value_expr_template => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '_CURRENT_TIMEZONE_'))",
        :data_type => :date,
        :groupable => true),
      :reviewed => new(
        :name => :reviewed,
        :name_expr_template => "IF(responses.reviewed, 'Yes', 'No')",
        :value_expr_template => "IF(responses.reviewed, 1, 0)",
        :data_type => :text,
        :groupable => true)
    }
end