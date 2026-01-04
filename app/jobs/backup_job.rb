# frozen_string_literal: true

class BackupJob < ApplicationJob
  queue_as :default

  def perform(backup_attributes)
    mission = Mission.find(backup_attributes["mission_id"])
    user = User.find(backup_attributes["user_id"])

    backup_service = BackupService.new(
      mission: mission,
      user: user,
      backup_type: backup_attributes["backup_type"],
      include_media: backup_attributes["include_media"],
      include_audit_logs: backup_attributes["include_audit_logs"]
    )

    begin
      backup = backup_service.create_backup

      # Notify user of successful backup
      NotificationService.create_for_user(
        user,
        "backup_complete",
        "Backup completed successfully",
        message: "Your #{backup.backup_type} backup for mission '#{mission.name}' has been completed.",
        data: {
          backup_id: backup.backup_id,
          backup_type: backup.backup_type,
          file_size: backup.file_size_mb
        },
        mission: mission
      )
    rescue StandardError => e
      # Notify user of failed backup
      NotificationService.create_for_user(
        user,
        "backup_failed",
        "Backup failed",
        message: "Your backup for mission '#{mission.name}' failed: #{e.message}",
        data: {
          error: e.message
        },
        mission: mission
      )

      raise e
    end
  end
end
