# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id         :uuid             not null, primary key
#  title      :string(255)      not null
#  message    :text
#  type       :string(255)      not null
#  read       :boolean          default(FALSE), not null
#  data       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#  mission_id :uuid
#
# Indexes
#
#  index_notifications_on_mission_id  (mission_id)
#  index_notifications_on_user_id     (user_id)
#  index_notifications_on_read        (read)
#  index_notifications_on_type        (type)
#
# Foreign Keys
#
#  notifications_mission_id_fkey  (mission_id => missions.id) ON DELETE => cascade
#  notifications_user_id_fkey     (user_id => users.id) ON DELETE => cascade
#

class Notification < ApplicationRecord
  include MissionBased

  # Disable Rails Single Table Inheritance (STI) because the `type` column is used for notification types,
  # not for polymorphic behavior. See: https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html
  self.inheritance_column = :_type_disabled

  belongs_to :user
  belongs_to :mission, optional: true

  validates :title, presence: true
  validates :type, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(type: type) }

  NOTIFICATION_TYPES = %w[
    form_submission
    form_published
    response_reviewed
    user_assigned
    data_export_complete
    system_alert
    mission_update
  ].freeze

  validates :type, inclusion: { in: NOTIFICATION_TYPES }

  def mark_as_read!
    update!(read: true)
  end

  def self.create_for_user(user, type, title, message: nil, data: {}, mission: nil)
    create!(
      user: user,
      type: type,
      title: title,
      message: message,
      data: data,
      mission: mission || user.current_mission
    )
  end

  def self.create_for_mission_users(mission, type, title, message: nil, data: {})
    mission.users.find_each do |user|
      create_for_user(user, type, title, message: message, data: data, mission: mission)
    end
  end

  def self.create_for_role(mission, role, type, title, message: nil, data: {})
    mission.users.where(assignments: { role: role }).find_each do |user|
      create_for_user(user, type, title, message: message, data: data, mission: mission)
    end
  end
end