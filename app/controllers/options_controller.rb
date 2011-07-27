class OptionsController < ApplicationController
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Option", params[:page])
    # get the questions
    @options = Option.sorted(@subindex.params)
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
