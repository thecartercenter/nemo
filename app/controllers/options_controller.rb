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
    destroy_and_handle_errors(@option)
    redirect_to(:action => :index)
  end
  
  def create
    create_or_update
  end
  
  def update
    @option.assign_attributes(params[:option])
    create_or_update
  end
  
  private
    # creates/updates the option
    def create_or_update
      if @option.save
        set_success_and_redirect(@option)
      else
        render(:form)
      end
    end
end
