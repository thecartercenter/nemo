# frozen_string_literal: true

# OperationsController
class OperationsController < ApplicationController
  PER_PAGE = 20

  # authorization via cancan
  load_and_authorize_resource

  decorates_assigned :operations

  def index
    unless Utils::DelayedJobChecker.instance.ok?
      flash.now[:error] = I18n.t("operation.errors.delayed_job_stopped")
    end

    @operations = if current_mission.present?
                    @operations.for_mission(current_mission).order(created_at: :desc)
                  else
                    @operations.order(created_at: :desc) # Display ALL operations on server
                  end
    @operations = @operations.paginate(page: params[:page], per_page: PER_PAGE)
  end

  def show
  end

  def destroy
    Delayed::Job.where(id: @operation.provider_job_id).destroy_all if @operation.provider_job_id.present?
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
