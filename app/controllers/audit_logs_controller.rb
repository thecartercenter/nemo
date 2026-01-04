# frozen_string_literal: true

class AuditLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission

  def index
    authorize!(:view, :audit_logs)

    @audit_logs = AuditLog.where(mission: @mission)
      .includes(:user)
      .recent
      .paginate(page: params[:page], per_page: 50)

    # Apply filters
    @audit_logs = @audit_logs.by_action(params[:action]) if params[:action].present?
    @audit_logs = @audit_logs.by_resource(params[:resource]) if params[:resource].present?
    @audit_logs = @audit_logs.by_user(User.find(params[:user_id])) if params[:user_id].present?

    if params[:date_from].present? && params[:date_to].present?
      @audit_logs = @audit_logs.in_date_range(
        Date.parse(params[:date_from]).beginning_of_day,
        Date.parse(params[:date_to]).end_of_day
      )
    end

    @actions = AuditLog::ACTIONS
    @resources = AuditLog::RESOURCES
    @users = User.joins(:assignments).where(assignments: {mission: @mission}).order(:name)
  end

  def show
    @audit_log = AuditLog.find(params[:id])
    authorize!(:view, :audit_logs)
  end

  def export
    authorize!(:export, :audit_logs)

    @audit_logs = AuditLog.where(mission: @mission)
      .includes(:user)
      .recent

    # Apply same filters as index
    @audit_logs = @audit_logs.by_action(params[:action]) if params[:action].present?
    @audit_logs = @audit_logs.by_resource(params[:resource]) if params[:resource].present?
    @audit_logs = @audit_logs.by_user(User.find(params[:user_id])) if params[:user_id].present?

    if params[:date_from].present? && params[:date_to].present?
      @audit_logs = @audit_logs.in_date_range(
        Date.parse(params[:date_from]).beginning_of_day,
        Date.parse(params[:date_to]).end_of_day
      )
    end

    respond_to do |format|
      format.csv do
        send_data(generate_csv(@audit_logs),
          filename: "audit_logs_#{@mission.shortcode}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
          type: "text/csv")
      end
    end
  end

  def statistics
    authorize!(:view, :audit_logs)

    @stats = {
      total_actions: AuditLog.where(mission: @mission).count,
      actions_by_type: AuditLog.where(mission: @mission)
        .group(:action)
        .count
        .sort_by { |_, count| -count },
      actions_by_user: AuditLog.where(mission: @mission)
        .joins(:user)
        .group("users.name")
        .count
        .sort_by { |_, count| -count }
        .first(10),
      actions_by_resource: AuditLog.where(mission: @mission)
        .group(:resource)
        .count
        .sort_by { |_, count| -count },
      recent_activity: AuditLog.where(mission: @mission)
        .where(created_at: 7.days.ago..Time.current)
        .group_by_day(:created_at)
        .count
    }

    respond_to do |format|
      format.html
      format.json { render(json: @stats) }
    end
  end

  private

  def set_mission
    @mission = current_mission
  end

  def generate_csv(audit_logs)
    CSV.generate do |csv|
      csv << [
        "Timestamp",
        "User",
        "Action",
        "Resource",
        "Resource Name",
        "Changes",
        "IP Address",
        "User Agent"
      ]

      audit_logs.find_each do |log|
        csv << [
          log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          log.user.name,
          log.human_readable_action,
          log.resource,
          log.resource_name,
          log.formatted_changes,
          log.ip_address,
          log.user_agent
        ]
      end
    end
  end
end
