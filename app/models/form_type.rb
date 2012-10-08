require 'seedable'
require 'mission_based'
class FormType < ActiveRecord::Base
  include Seedable
  include MissionBased
  
  has_many(:forms, :inverse_of => :type)
  
  before_destroy(:check_assoc)
  
  validates(:name, :presence => :true, :length => {:maximum => 16})
  
  default_scope(order("name"))
  
  def self.generate
    seed(:name, :name => "Type 1")
    seed(:name, :name => "Type 2")
  end
  
  private
    def check_assoc
      unless forms.empty?
        raise "You can't delete Form Type '#{name}' because one or more forms are associated with it."
      end
    end
end
