class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def update
    if params[:parent_id].blank? or !@form_item.check_ancestry_integrity(params[:parent_id])
      return render json: { errors: ['ancestry_check_failed'] }, status: 422
    end

    @form_item.parent = FormItem.find(params[:parent_id])
    @form_item.rank = params[:rank]

    if @form_item.save
      render nothing: true, status: 204
    else
      render @form_item.errors, status: 422
    end
  end
end
