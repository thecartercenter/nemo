# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: assignments
#
#  id         :uuid             not null, primary key
#  role       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_assignments_on_mission_id              (mission_id)
#  index_assignments_on_mission_id_and_user_id  (mission_id,user_id) UNIQUE
#  index_assignments_on_user_id                 (user_id)
#
# Foreign Keys
#
#  assignments_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  assignments_user_id_fkey     (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

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

  def enumerator?
    role == "enumerator"
  end

  private

  def normalize_role
    self.role = nil unless User::ROLES.include?(role)
  end
end
