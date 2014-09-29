# models response attributes that are not answers to questions (user, date, etc.)
class Report::AttribField < Report::Field

  attr_accessor :name, :name_expr_params, :value_expr_params, :data_type, :groupable

  # builds one of each type of AttribField
  def self.all
    @@ATTRIBS.values.collect{|a| new(a[:name])}
  end

  # builds a new object from the templates at the bottom of the file
  def initialize(attrib_name)
    raise "attrib_name #{attrib_name} not found when creating AttribField object" unless @@ATTRIBS[attrib_name.to_sym]
    @@ATTRIBS[attrib_name.to_sym].each{|k,v| self.send("#{k}=", v)}
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
    {:name => name, :title => title}
  end

  def title
    I18n.t("attrib_fields.#{name}", default: name.to_s.gsub('_', ' ').ucwords)
  end

  private
    def joins=(j)
      @joins = j
    end

    @@ATTRIBS = {
      :response_id => {
        :name => :response_id,
        :name_expr_params => {:sql_tplt => "CONCAT('#',responses.id)", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "CONCAT('#',responses.id)", :name => "value", :clause => :select},
        :data_type => :text},
      :form => {
        :name => :form,
        :name_expr_params => {:sql_tplt => "__TBL_PFX__forms.name", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "__TBL_PFX__forms.name", :name => "value", :clause => :select},
        :joins => [:forms],
        :data_type => :text,
        :groupable => true},
      :submitter => {
        :name => :submitter,
        :name_expr_params => {:sql_tplt => "__TBL_PFX__users.name", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "__TBL_PFX__users.name", :name => "value", :clause => :select},
        :joins => [:users],
        :data_type => :text,
        :groupable => true},
      :source => {
        :name => :source,
        :name_expr_params => {:sql_tplt => "responses.source", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "responses.source", :name => "value", :clause => :select},
        :data_type => :text,
        :groupable => true},
      :time_submitted => {
        :name => :time_submitted,
        :name_expr_params => {:sql_tplt => "responses.created_at", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "responses.created_at", :name => "value", :clause => :select},
        :data_type => :datetime},
      :date_submitted => {
        :name => :date_submitted,
        :name_expr_params => {:sql_tplt => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '__CURRENT_TIMEZONE__'))", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '__CURRENT_TIMEZONE__'))", :name => "value", :clause => :select},
        :data_type => :date,
        :groupable => true},
      :reviewed => {
        :name => :reviewed,
        :name_expr_params => {:sql_tplt => "IF(responses.reviewed, 'Yes', 'No')", :name => "name", :clause => :select},
        :value_expr_params => {:sql_tplt => "IF(responses.reviewed, 1, 0)", :name => "value", :clause => :select},
        :data_type => :text,
        :groupable => true}
    }
end