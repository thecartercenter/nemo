class Assignment < ApplicationRecord
  include Cacheable

  belongs_to(:mission)
  belongs_to(:user, :inverse_of => :assignments)

  before_validation(:normalize_role)

  validates(:mission, :presence => true)
  validates(:role, presence: true, unless: lambda { |a| a.user.admin? })

  scope(:sorted_recent_first, -> { order("created_at DESC") })

  # checks if there are any duplicates in the given set of assignments
  def self.duplicates?(assignments)
    # uniq! returns nil if there are no duplicates
    !assignments.collect{|a| a.mission}.compact.uniq!.nil?
  end

  # When a mission is deleted, remove all sms messages from that mission
  def self.mission_pre_delete(mission)
    self.delete_all(mission_id:mission)
  end

  # generates a cache key for the set of all assignments for the given mission.
  # the key will change if the number of assignments changes, or if an assignment is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(:rel => unscoped.where(:mission_id => mission.id), :prefix => "mission-#{mission.id}")
  end

  def no_role?
    role.blank?
  end

  # human readable
  def to_s
    ""
  end

  private

    # ensures role is one of allowable values
    def normalize_role
      self.role = nil unless User::ROLES.include?(role)
    end
end
