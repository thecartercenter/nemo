class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  after_action :check_rank_fail

  def update
    # Blank parent_id means parent is root
    params[:parent_id] = @form_item.form.root_id if params[:parent_id].blank?

    # Moves to new position and attempts to save.
    @form_item.move(params[:parent_id], params[:rank])

    if @form_item.valid?
      render nothing: true, status: 204
    else
      render @form_item.errors, status: 422
    end
  end
end
