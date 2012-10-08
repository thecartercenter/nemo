class OptionsController < ApplicationController
  def index
    @options = apply_filters(Option)
  end
  
  def new
    @option = Option.for_mission(current_mission).new
    render_form
  end
  
  def edit
    @option = Option.find(params[:id])
    render_form
  end

  def show
    @option = Option.find(params[:id])
    render_form
  end

  def destroy
    @option = Option.find(params[:id])
    begin flash[:success] = @option.destroy && "Option deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  def update; crupdate; end
  
  private
    def crupdate
      action = params[:action]
      @option = action == "create" ? Option.for_mission(current_mission).new : Option.find(params[:id])
      begin
        @option.update_attributes!(params[:option])
        flash[:success] = "Option #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        render_form
      end
    end
    
    def render_form
      render(:form)
    end
end
