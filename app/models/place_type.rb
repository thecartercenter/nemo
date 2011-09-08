class PlaceType < ActiveRecord::Base
  def self.sorted
    all(:order => "level")
  end
  def self.except_point
    all(:conditions => "level <= 4", :order => "level")
  end
  def self.select_options
    sorted.reverse.collect{|pt| [pt.name, pt.id]}
  end
  def self.address
    find_by_level(4)
  end
  def self.point
    find_by_level(5)
  end
  def is_address?
    level == 4
  end
end
