# frozen_string_literal: true

class ExportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission

  def new
    authorize!(:export, :data)
    @export_service = DataExportService.new(mission: @mission, user: current_user)
    @forms = Form.accessible_by(current_ability).where(mission: @mission)
    @users = User.joins(:assignments).where(assignments: {mission: @mission})
  end

  def create
    authorize!(:export, :data)

    @export_service = DataExportService.new(export_params.merge(mission: @mission, user: current_user))

    if @export_service.valid?
      begin
        export_data = @export_service.export

        # Send notification when export is complete
        NotificationService.notify_data_export_complete(
          current_user,
          "#{@export_service.export_type} (#{@export_service.format.upcase})",
          @export_service.filename
        )

        respond_to do |format|
          format.html do
            send_data(export_data,
              filename: @export_service.filename,
              type: mime_type_for_format(@export_service.format),
              disposition: "attachment")
          end
          format.json do
            render(json: {
              success: true,
              message: "Export completed successfully",
              filename: @export_service.filename,
              download_url: download_export_path(@export_service.filename)
            })
          end
        end
      rescue StandardError => e
        respond_to do |format|
          format.html do
            flash[:error] = "Export failed: #{e.message}"
            redirect_to(new_export_path)
          end
          format.json do
            render(json: {
              success: false,
              message: "Export failed: #{e.message}"
            }, status: :internal_server_error)
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          @forms = Form.accessible_by(current_ability).where(mission: @mission)
          @users = User.joins(:assignments).where(assignments: {mission: @mission})
          render(:new)
        end
        format.json do
          render(json: {
            success: false,
            message: "Invalid export parameters",
            errors: @export_service.errors.full_messages
          }, status: :unprocessable_content)
        end
      end
    end
  end

  def download
    authorize!(:export, :data)

    params[:filename]
    # In a real implementation, you'd want to store the export files temporarily
    # and serve them from a secure location
    redirect_to(root_path, alert: "Download functionality not implemented yet")
  end

  def status
    authorize!(:export, :data)

    # This would check the status of background export jobs
    render(json: {status: "completed"})
  end

  private

  def set_mission
    @mission = current_mission
  end

  def export_params
    params.require(:data_export_service).permit(
      :export_type, :format, :include_media,
      filters: [
        :date_from, :date_to, :incomplete,
        {form_ids: [], user_ids: [], sources: []}
      ]
    )
  end

  def mime_type_for_format(format)
    case format
    when "csv"
      "text/csv"
    when "excel"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when "pdf"
      "application/pdf"
    when "json"
      "application/json"
    when "xml"
      "application/xml"
    else
      "application/octet-stream"
    end
  end
end
