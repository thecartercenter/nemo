require 'seedable'
require 'mission_based'
class FormType < ActiveRecord::Base
  include MissionBased
  
  has_many(:forms, :inverse_of => :type)
  
  before_destroy(:check_assoc)
  
  validates(:name, :presence => :true, :length => {:maximum => 16})
  
  default_scope(order("name"))
  
  # creates and returns a default set of form types for the given mission
  def self.create_default(mission)
    ["Short Term", "Long Term", "Security"].collect{|n| create(:name => n, :mission => mission)}
  end
  
  private
    def check_assoc
      unless forms.empty?
        raise "You can't delete Form Type '#{name}' because one or more forms are associated with it."
      end
    end
end
