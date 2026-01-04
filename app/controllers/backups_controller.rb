# frozen_string_literal: true

class BackupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission
  before_action :set_backup, only: %i[show download restore destroy]

  def index
    authorize!(:view, :backups)

    @backups = Backup.where(mission: @mission)
      .includes(:user)
      .recent
      .paginate(page: params[:page], per_page: 20)

    @backup_types = Backup::BACKUP_TYPES
  end

  def show
    authorize!(:view, @backup)
  end

  def new
    authorize!(:create, :backups)
    @backup_service = BackupService.new(mission: @mission, user: current_user)
  end

  def create
    authorize!(:create, :backups)

    @backup_service = BackupService.new(backup_params.merge(mission: @mission, user: current_user))

    if @backup_service.valid?
      begin
        # Create backup in background job
        BackupJob.perform_later(@backup_service.attributes)

        redirect_to(backups_path, notice: "Backup started. You will be notified when it is complete.")
      rescue StandardError => e
        redirect_to(new_backup_path, alert: "Failed to start backup: #{e.message}")
      end
    else
      render(:new)
    end
  end

  def download
    authorize!(:download, @backup)

    if @backup.file_exists?
      send_file(@backup.file_path,
        filename: "backup_#{@backup.backup_id}.tar.gz",
        type: "application/gzip")
    else
      redirect_to(backups_path, alert: "Backup file not found.")
    end
  end

  def restore
    authorize!(:restore, @backup)

    unless @backup.can_be_restored_by?(current_user)
      redirect_to(backups_path, alert: "You do not have permission to restore this backup.")
      return
    end

    begin
      BackupService.restore_backup(@backup.file_path, current_user, @mission)
      redirect_to(backups_path, notice: "Backup restored successfully.")
    rescue StandardError => e
      redirect_to(backups_path, alert: "Failed to restore backup: #{e.message}")
    end
  end

  def destroy
    authorize!(:destroy, @backup)

    unless @backup.can_be_deleted_by?(current_user)
      redirect_to(backups_path, alert: "You do not have permission to delete this backup.")
      return
    end

    @backup.cleanup!
    redirect_to(backups_path, notice: "Backup deleted successfully.")
  end

  def cleanup_old
    authorize!(:manage, :backups)

    days = params[:days]&.to_i || 30
    Backup.cleanup_old_backups(days)

    redirect_to(backups_path, notice: "Cleaned up backups older than #{days} days.")
  end

  private

  def set_mission
    @mission = current_mission
  end

  def set_backup
    @backup = Backup.find(params[:id])
  end

  def backup_params
    params.require(:backup_service).permit(
      :backup_type, :include_media, :include_audit_logs
    )
  end
end
