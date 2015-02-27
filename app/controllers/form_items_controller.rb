class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  before_filter :prepare_form_item, only: [:update]

  def update
    if @form_item.save
      render nothing: true, status: 204
    else
      render nothing: true, status: 422
    end
  end

  private
    # prepares form item
    def prepare_form_item
      attrs = params[:form_item]

      if attrs.blank? or !@form_item.check_ancestry_integrity(attrs[:ancestry])
        return render nothing: true, status: 422
      end

      @form_item.ancestry = attrs[:ancestry]
      @form_item.rank = attrs[:rank]
    end
end
