class FormTypesController < ApplicationController
  def index
    @form_types = apply_filters(FormType)
  end
  
  def new
    @form_type = FormType.new
    render(:form)
  end
  
  def edit
    @form_type = FormType.find(params[:id])
    render(:form)
  end

  def show
    @form_type = FormType.find(params[:id])
    render(:form)
  end

  def destroy
    @form_type = FormType.find(params[:id])
    begin 
      flash[:success] = @form_type.destroy && "Form Type deleted successfully." 
    rescue
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  def update; crupdate; end

  private
    def crupdate
      action = params[:action]
      @form_type = action == "create" ? FormType.for_mission(current_mission).new : FormType.find(params[:id])
      begin
        @form_type.update_attributes!(params[:form_type])
        flash[:success] = "Form Type #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        render(:form)
      end
    end
end
