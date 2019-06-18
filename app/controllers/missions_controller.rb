# frozen_string_literal: true

# MissionsController
class MissionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  decorates_assigned :missions

  def index
  end

  def new
    render(:form)
  end

  def show
    render(:form)
  end

  def edit
    render(:form)
  end

  def create
    @mission.save!
    set_success_and_redirect(@mission)
  rescue ActiveRecord::RecordInvalid
    flash.now[:error] = I18n.t("activerecord.errors.models.mission.general")
    render(:form)
  end

  def update
    @mission.update!(mission_params)
    set_success_and_redirect(@mission)
  rescue ActiveRecord::RecordInvalid
    render(:form)
  end

  def destroy
    destroy_and_handle_errors(@mission)
    redirect_to(index_url_with_context)
  end

  private

  def mission_params
    params.require(:mission).permit(:name, :locked)
  end
end
