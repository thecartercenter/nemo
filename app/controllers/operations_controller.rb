# frozen_string_literal: true

# OperationsController
class OperationsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def index
    @operations = if current_mission.present?
                    @operations.for_mission(current_mission).order(created_at: :desc)
                  else
                    @operations.order(created_at: :desc) # Display ALL operations on server
                  end
  end

  def show
  end

  def download
    unless @operation.attachment.present?
      flash[:error] = t("operation.no_attachment")
      redirect_to operation_path(@operation)
    end

    send_file(@operation.attachment.path, filename: @operation.attachment_filename)
  end

  def destroy
    destroy_and_handle_errors(@operation)
    redirect_to(index_url_with_context)
  end

  def clear
    @operations.each do |op|
      op.destroy if can?(:destroy, op)
    end

    redirect_to(index_url_with_context)
  end
end
