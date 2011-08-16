class OptionsController < ApplicationController
  def index
    @options = load_objects_with_subindex(Option)
  end
  
  def new
    @option = Option.new
  end
  
  def edit
    @option = Option.find(params[:id])
  end

  def show
    @option = Option.find(params[:id])
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
      @option = action == "create" ? Option.new : Option.find(params[:id])
      begin
        @option.update_attributes!(params[:option])
        flash[:success] = "Option #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        render(:action => action == "create" ? :new : :edit)
      end
    end
end
