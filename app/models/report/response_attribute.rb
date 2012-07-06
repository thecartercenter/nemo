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
    seed(:name, :name => "State", :code => "states.long_name", :join_tables => "states", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Country", :code => "countries.long_name", :join_tables => "countries", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Submitter", :code => "users.name", :join_tables => "users", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Source", :code => "responses.source", 
      :data_type => "text", :groupable => true)
    seed(:name, :name => "Locality", :code => "localities.long_name", 
      :data_type => "text", :join_tables => "localities", :groupable => true)
    seed(:name, :name => "Time Observed", :code => "responses.observed_at",
      :data_type => "datetime")
    seed(:name, :name => "Date Observed", :code => "DATE_FORMAT(DATE(responses.observed_at), '%Y-%m-%d')", 
      :data_type => "date", :groupable => true)
    seed(:name, :name => "Date Submitted", :code => "DATE_FORMAT(DATE(responses.created_at), '%Y-%m-%d')", 
      :data_type => "date", :groupable => true)
    seed(:name, :name => "Reviewed", :code => "if(responses.reviewed, 'Yes', 'No')", 
      :data_type => "text", :groupable => true)
  end
  
  # returns the sql fragment for the select clause
  def to_sql
    code
  end
  
  def has_timezone?
    data_type == "datetime"
  end
  
  def temporal?
    %w(datetime date time).include?(data_type)
  end
  
  def apply(rel, options = {})
    rel = rel.select("#{to_sql} AS `#{sql_col_name}`")
    rel = apply_joins(rel)
    rel = rel.group(to_sql) if options[:group]
    rel
  end
    
  def sql_col_name
    "attrib_#{name.gsub(' ','_').downcase}"
  end
  
  def apply_joins(rel)
    join_tables ? rel.joins(Report::Join.list_to_sql(join_tables.split(","))) : rel
  end
  
  def header
    {:name => name, :value => name, :key => sql_col_name, :fieldlet => self}
  end
end
