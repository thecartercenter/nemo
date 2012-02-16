require 'seedable'
class Report::GroupingAttribute < ActiveRecord::Base
  include Seedable
  
  default_scope(order("name"))
  
  def self.generate
    seed(:name, :name => "Form", :code => "forms.name", :join_tables => "forms")
    seed(:name, :name => "Form Type", :code => "form_types.name", :join_tables => "form_types")
    seed(:name, :name => "State", :code => "states.long_name", :join_tables => "states")
    seed(:name, :name => "Country", :code => "countries.long_name", :join_tables => "countries")
    seed(:name, :name => "Submitter", :code => "users.name", :join_tables => "users")
    seed(:name, :name => "Source", :code => "responses.source")
    seed(:name, :name => "Locality", :code => "localities.long_name", :join_tables => "localities")
    seed(:name, :name => "Date Observed", :code => "DATE(responses.observed_at)")
    seed(:name, :name => "Date Submitted", :code => "DATE(responses.created_at)")
    seed(:name, :name => "Reviewed", :code => "if(responses.reviewed, 'Yes', 'No')")
  end
end
