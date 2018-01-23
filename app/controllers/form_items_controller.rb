class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  after_action :check_rank_fail

  def update
    # Blank parent_id means parent is root
    params[:parent_id] = @form_item.form.root_id if params[:parent_id].blank?

    @form_item.move(FormItem.find(params[:parent_id]), params[:rank].to_i)
    render nothing: true, status: 204
  end
end
