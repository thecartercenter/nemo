class OptionSetImportsController < ApplicationController
  load_and_authorize_resource

  def new
    render('form')
  end

  def create
    if @option_set_import.valid?
      flash[:notice] = %{Option set import queued}
      redirect_to(option_sets_url)
    else
      flash.now[:error] = I18n.t('activerecord.errors.models.option_set_import.general')
      render('form')
    end
  end

  protected

    def option_set_import_params
      params.require(:option_set_import).permit(:name, :file) do |whitelisted|
        whitelisted[:mission_id] = current_mission.id
      end
    end
end
