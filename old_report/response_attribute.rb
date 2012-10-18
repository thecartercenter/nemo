require 'seedable'
class Report::ResponseAttribute < ActiveRecord::Base
  include Seedable
    
  default_scope(order("name"))
  scope(:groupable, where(:groupable => true))
  
  def self.generate
    seed(:name, :name => "Form", :code => "forms.name", :join_tables => "forms", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Form Type", :code => "form_types.name", :join_tables => "form_types", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Submitter", :code => "users.name", :join_tables => "users", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Source", :code => "responses.source", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Time Submitted", :code => "responses.created_at",
      :data_type => "datetime")
    seed(:name, :name => "Date Submitted", :code => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '%CURRENT_TIMEZONE%'))", 
      :data_type => "date", :groupable => true)
    seed(:name, :name => "Reviewed", :code => "IF(responses.reviewed, 'Yes', 'No')", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Question Title", :code => "question_trans.str", :join_tables => "question_trans", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Question Code", :code => "questions.code", :join_tables => "questions", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Answer (Option Name)", 
      :code => "IFNULL(aotr.str, cotr.str)",
      :value_code => "CONCAT(option_sets.name, IF(option_sets.ordering = 'value_asc', IFNULL(ao.value, co.value), 1000000 - IFNULL(ao.value, co.value)))",
      :join_tables => "choices,options,option_sets",
      :data_type => "text", :groupable => true)

    # deprecated
    unseed(:name, "Date Observed")
    unseed(:name, "Time Observed")
    
    # these are no longer special fields
    unseed(:name, "Locality")
    unseed(:name, "State")
    unseed(:name, "Country")
  end
  
  # returns the sql fragment for the select clause
  def to_sql
    # we must convert the timezone before using the DATE function
    code.gsub("%CURRENT_TIMEZONE%", Time.zone.mysql_name)
  end
  
  def has_timezone?
    data_type == "datetime"
  end
  
  def temporal?
    %w(datetime date time).include?(data_type)
  end
  
  def apply(rel, options = {})
    rel = rel.select("#{to_sql} AS `#{sql_col_name}`")
    rel = rel.select("#{value_code} AS `#{sql_value_col_name}`") if value_code
    rel = apply_joins(rel)
    rel = rel.group(to_sql) if options[:group]
    rel
  end
    
  def sql_col_name
    "attrib_#{name.gsub(' ','_').downcase}"
  end
  
  def sql_value_col_name
    sql_col_name + "_value"
  end
  
  def apply_joins(rel)
    join_tables ? rel.joins(Report::Join.list_to_sql(join_tables.split(","))) : rel
  end
  
  def header
    {:name => name, :value => name, :key => sql_col_name, :fieldlet => self}
  end
end
