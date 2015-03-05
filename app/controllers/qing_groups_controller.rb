class QingGroupsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  before_filter :prepare_qing_group, only: [:create]
  before_filter :validate_destroy, only: [:destroy]

  def create
    create_or_update
  end

  def update
    @qing_group.assign_attributes(params[:qing_group])
    create_or_update
  end

  def destroy
    begin
      @qing_group.destroy
      render nothing: true, status: 204
    end
  end

  private
    # creates/updates the qing_group
    def create_or_update
      if @qing_group.save
        render(partial: 'form')
      else
        render(:form)
      end
    end

    def validate_destroy
      if @qing_group.children.size > 0
        render :json => [], :status => 404
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
