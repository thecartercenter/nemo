class PlaceType < ActiveRecord::Base
  def self.sorted
    all(:order => "level")
  end
  def self.select_options
    sorted.reverse.collect{|pt| [pt.name, pt.id]}
  end
  def self.address
    find_by_level(4)
  end
  def is_address?
    level == 4
  end
end
