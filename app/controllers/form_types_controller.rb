class FormTypesController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource
  
  def index
  end
  
  def new
    render(:form)
  end
  
  def edit
    render(:form)
  end

  def show
    render(:form)
  end

  def destroy
    destroy_and_handle_errors(@form_type)
    redirect_to(:action => :index)
  end
  
  def create
    if @form_type.save
      set_success_and_redirect(@form_type)
    else
      render(:form)
    end
  end
  
  def update
    if @form_type.update_attributes(params[:form_type])
      set_success_and_redirect(@form_type)
    else
      render(:form)
    end
  end
end
