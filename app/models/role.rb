class Role < ActiveRecord::Base
  def self.sorted
    find(:all, :order => "level")
  end
  def self.select_options
    sorted.collect{|r| [r.name, r.id]}
  end
  def to_s
    name
  end
end
