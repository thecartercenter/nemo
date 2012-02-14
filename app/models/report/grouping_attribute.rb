require 'seedable'
class Report::GroupingAttribute < ActiveRecord::Base
  include Seedable
  
  def self.generate
    seed(:name, :name => "Form", :code => "forms.name", :join_tables => "forms")
    seed(:name, :name => "State", :code => "states.long_name", :join_tables => "states")
    seed(:name, :name => "Country", :code => "countries.long_name", :join_tables => "countries")
  end
end
