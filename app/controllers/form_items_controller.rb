class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def update
    attrs = params[:form_item]

    if attrs[:ancestry].blank? or !@form_item.check_ancestry_integrity(attrs[:ancestry])
      return render nothing: true, status: 422
    end

    @form_item.ancestry = attrs[:ancestry]
    @form_item.rank = attrs[:rank]

    if @form_item.save
      render nothing: true, status: 204
    else
      render nothing: true, status: 422
    end
  end
end
