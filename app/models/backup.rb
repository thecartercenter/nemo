# frozen_string_literal: true

# == Schema Information
#
# Table name: backups
#
#  id                :uuid             not null, primary key
#  backup_id         :string(255)      not null
#  backup_type       :string(255)      not null
#  file_path         :string(255)      not null
#  file_size         :bigint           not null
#  include_media     :boolean          default(FALSE), not null
#  include_audit_logs :boolean         default(FALSE), not null
#  status            :string(255)      default("completed"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid             not null
#  user_id           :uuid             not null
#
# Indexes
#
#  index_backups_on_backup_id    (backup_id) UNIQUE
#  index_backups_on_mission_id   (mission_id)
#  index_backups_on_user_id      (user_id)
#  index_backups_on_status       (status)
#  index_backups_on_created_at   (created_at)
#
# Foreign Keys
#
#  backups_mission_id_fkey  (mission_id => missions.id) ON DELETE => cascade
#  backups_user_id_fkey     (user_id => users.id) ON DELETE => cascade
#

class Backup < ApplicationRecord
  include MissionBased

  belongs_to :mission
  belongs_to :user

  validates :backup_id, presence: true, uniqueness: true
  validates :backup_type, presence: true
  validates :file_path, presence: true
  validates :file_size, presence: true, numericality: {greater_than: 0}

  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :recent, -> { order(created_at: :desc) }

  BACKUP_TYPES = %w[full mission_data forms_only responses_only].freeze
  STATUSES = %w[in_progress completed failed].freeze

  validates :backup_type, inclusion: {in: BACKUP_TYPES}
  validates :status, inclusion: {in: STATUSES}

  def file_exists?
    File.exist?(file_path)
  end

  def file_size_mb
    (file_size / 1024.0 / 1024.0).round(2)
  end

  def download_url
    # In a real implementation, this would generate a secure download URL
    "/backups/#{backup_id}/download"
  end

  def can_be_restored_by?(user)
    return false unless completed?
    return false unless file_exists?

    user.admin? || user.missions.include?(mission)
  end

  def can_be_deleted_by?(user)
    user.admin? || user == self.user || user.role(mission) == "coordinator"
  end

  def cleanup!
    File.delete(file_path) if file_exists?
    destroy!
  end

  def self.cleanup_old_backups(days = 30)
    where("created_at < ?", days.days.ago).find_each(&:cleanup!)
  end
end
