class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def update
    # Blank parent_id means parent is root
    params[:parent_id] = @form_item.form.root_id if params[:parent_id].blank?

    @form_item.parent = FormItem.find(params[:parent_id])
    @form_item.rank = params[:rank]

    if @form_item.save
      render nothing: true, status: 204
    else
      render @form_item.errors, status: 422
    end
  end
end
