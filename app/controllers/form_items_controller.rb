class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def update
    if params[:ancestry].blank? or !@form_item.check_ancestry_integrity(params[:ancestry])
      return render nothing: true, status: 422
    end

    @form_item.ancestry = params[:ancestry]
    @form_item.rank = params[:rank]

    if @form_item.save
      render nothing: true, status: 204
    else
      render nothing: true, status: 422
    end
  end
end
