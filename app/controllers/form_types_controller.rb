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
    begin 
      flash[:success] = @form_type.destroy && "Form Type deleted successfully." 
    rescue
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  
  def create
    if @form_type.update_attributes(params[:form_type])
      flash[:success] = "Form Type created successfully."
      redirect_to(:action => :index)
    else
      render(:form)
    end
  end
  
  def update
    if @form_type.update_attributes(params[:form_type])
      flash[:success] = "Form Type updated successfully."
      redirect_to(:action => :index)
    else
      render(:form)
    end
  end
end
