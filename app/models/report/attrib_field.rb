# models response attributes that are not answers to questions (user, date, etc.)
class Report::AttribField < Report::Field
  
  attr_accessor :name, :name_expr_params, :value_expr_params, :data_type, :groupable
  
  def self.get(name)
    @@ATTRIBS[name.to_sym]
  end
  
  def self.all
    @@ATTRIBS.values
  end

  def name_expr(chunks)
    @name_expr ||= Report::Expression.new(name_expr_params.merge(:chunks => chunks.merge(:current_timezone => Time.zone.mysql_name)))
  end
  
  def value_expr(chunks)
    @value_expr ||= Report::Expression.new(value_expr_params.merge(:chunks => chunks.merge(:current_timezone => Time.zone.mysql_name)))
  end
  
  def where_expr(chunks)
    @where_expr ||= Report::Expression.new(:sql_tplt => "", :name => "where", :clause => :where)
  end
  
  def sort_expr(chunks)
    @sort_expr ||= name_expr(chunks)
  end
  
  def joins
    @joins || []
  end
  
  def as_json(options = {})
    {:name => name, :title => name.to_s.gsub("_", " ").ucwords}
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
        :name_expr_params => {:sql_tplt => "__TBL_PFX__forms.name", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "__TBL_PFX__forms.name", :name => "value", :clause => :select},
        :joins => [:forms],
        :data_type => :text,
        :groupable => true),
      :form_type => new(
        :name => :form_type,
        :name_expr_params => {:sql_tplt => "__TBL_PFX__form_types.name", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "__TBL_PFX__form_types.name", :name => "value", :clause => :select},
        :joins => [:form_types],
        :data_type => :text,
        :groupable => true),
      :submitter => new(
        :name => :submitter,
        :name_expr_params => {:sql_tplt => "__TBL_PFX__users.name", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "__TBL_PFX__users.name", :name => "value", :clause => :select},
        :joins => [:users],
        :data_type => :text,
        :groupable => true),
      :source => new(
        :name => :source,
        :name_expr_params => {:sql_tplt => "responses.source", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "responses.source", :name => "value", :clause => :select},
        :data_type => :text,
        :groupable => true),
      :time_submitted => new(
        :name => :time_submitted,
        :name_expr_params => {:sql_tplt => "responses.created_at", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "responses.created_at", :name => "value", :clause => :select},
        :data_type => :datetime),
      :date_submitted => new(
        :name => :date_submitted,
        :name_expr_params => {:sql_tplt => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '__CURRENT_TIMEZONE__'))", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '__CURRENT_TIMEZONE__'))", :name => "value", :clause => :select},
        :data_type => :date,
        :groupable => true),
      :reviewed => new(
        :name => :reviewed,
        :name_expr_params => {:sql_tplt => "IF(responses.reviewed, 'Yes', 'No')", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "IF(responses.reviewed, 1, 0)", :name => "value", :clause => :select},
        :data_type => :text,
        :groupable => true)
    }
end