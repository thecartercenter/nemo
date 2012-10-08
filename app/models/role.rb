require 'seedable'
class Role < ActiveRecord::Base
  include Seedable
  
  has_many(:assignments, :inverse_of => :role)
  
  default_scope(order("level DESC"))

  def self.generate
    seed(:level, :name => "Coordinator", :level => "3")
    seed(:level, :name => "Staffer", :level => "2")
    seed(:level, :name => "Observer", :level => "1")
  end
  
  def self.highest
    unscoped.order("level DESC").first
  end

  def self.lowest
    unscoped.order("level").first
  end
        
  def to_s
    name
  end
  def observer?; level == 1; end
  def coordinator?; level == 3; end
end
