class PlaceType < ActiveRecord::Base
  def self.sorted
    all(:order => "level")
  end
  def self.select_options
    sorted.reverse.collect{|pt| [pt.name, pt.id]}
  end
end
