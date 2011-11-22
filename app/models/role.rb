class Role < ActiveRecord::Base
  has_many(:users)
  
  def self.sorted
    find(:all, :order => "level")
  end
  def self.select_options
    sorted.collect{|r| [r.name, r.id]}
  end
  def to_s
    name
  end
  def is_observer?; level == 1; end
  def is_program_staff?; level == 4; end
end
