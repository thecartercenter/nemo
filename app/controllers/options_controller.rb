class OptionsController < ApplicationController
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
    begin flash[:success] = @option.destroy && "Option deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  def create
    create_or_update
  end
  
  def update
    create_or_update
  end
  
  private
    # creates/updates the option
    def create_or_update
      if @option.update_attributes(params[:option])
        flash[:success] = "Option #{params[:action]}d successfully."
        redirect_to(:action => :index)
      else
        prepare_and_render_form
      end
    end
end
