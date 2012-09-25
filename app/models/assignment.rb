class Assignment < ActiveRecord::Base
  belongs_to(:mission)
  belongs_to(:role, :inverse_of => :assignments)
  belongs_to(:user, :inverse_of => :assignments)

  validates(:mission, :presence => true)
  validates(:role, :presence => true)

  default_scope(includes(:mission, :role))
  scope(:sorted_recent_first, order("created_at DESC"))
  scope(:active, where(:active => true))
  
  # checks if there are any duplicates in the given set of assignments
  def self.duplicates?(assignments)
    # uniq! returns nil if there are no duplicates
    !assignments.collect{|a| a.mission}.compact.uniq!.nil?
  end
end
