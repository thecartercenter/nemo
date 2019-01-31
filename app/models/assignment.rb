# frozen_string_literal: true

# Assignment of a user to a mission.
class Assignment < ApplicationRecord
  include Cacheable

  belongs_to :mission
  belongs_to :user, inverse_of: :assignments

  before_validation :normalize_role

  validates :mission, presence: true
  validates :role, presence: true, unless: ->(a) { a.user.admin? }

  scope :sorted_recent_first, -> { order("created_at DESC") }

  delegate :name, to: :mission, prefix: true

  # checks if there are any duplicates in the given set of assignments
  def self.duplicates?(assignments)
    # uniq! returns nil if there are no duplicates
    !assignments.collect(&:mission).compact.uniq!.nil?
  end

  # generates a cache key for the set of all assignments for the given mission.
  # the key will change if the number of assignments changes, or if an assignment is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(rel: where(mission_id: mission.id), prefix: "mission-#{mission.id}")
  end

  def self.mission_pre_delete(mission)
    where(mission: mission).delete_all
  end

  def no_role?
    role.blank?
  end

  def to_s
    ""
  end

  private

  def normalize_role
    self.role = nil unless User::ROLES.include?(role)
  end
end
