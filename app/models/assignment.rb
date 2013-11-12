class Assignment < ActiveRecord::Base
  belongs_to(:mission)
  belongs_to(:user, :inverse_of => :assignments)

  validates(:mission, :presence => true)
  validates(:role, :presence => true)

  default_scope(includes(:mission))
  scope(:sorted_recent_first, order("created_at DESC"))
  scope(:active, where(:active => true))
  
  # checks if there are any duplicates in the given set of assignments
  def self.duplicates?(assignments)
    # uniq! returns nil if there are no duplicates
    !assignments.collect{|a| a.mission}.compact.uniq!.nil?
  end

  # When a mission is deleted, remove all sms messages from that mission
  def self.mission_pre_delete(mission)
    self.delete_all(mission_id:mission)
  end
end
