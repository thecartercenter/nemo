class QingGroupsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  before_filter :prepare_qing_group, :only => [:create]

  def new
    @qing_group = QingGroup.new(:form_id => params[:id])
    render(:form)
  end

  def edit
    render(:form)
  end

  def show
    render(:form)
  end

  def create
    create_or_update
  end

  def update
    @qing_group.assign_attributes(params[:qing_group])
    create_or_update
  end

  def destroy
    destroy_and_handle_errors(@qing_group)
    redirect_to(edit_form_url(@qing_group.form))
  end

  private
    # creates/updates the qing_group
    def create_or_update
      if @qing_group.save
        render(:partial => 'item')
      else
        render(:form)
      end
    end

    # prepares qing_group
    def prepare_qing_group
      attrs = params[:qing_group]
      attrs[:ancestry] = Form.find(attrs[:form_id]).root_id
      @qing_group = QingGroup.accessible_by(current_ability).new(attrs)
      @qing_group.mission = current_mission
    end
end
