class OptionSetsController < ApplicationController
  def index
    @sets = apply_filters(OptionSet).for_index
  end
  
  def new
    @set = OptionSet.for_mission(current_mission).new
    render_form
  end
  
  def edit
    @set = OptionSet.find(params[:id])
    render_form
  end

  def show
    @set = OptionSet.find(params[:id])
    render_form
  end

  def destroy
    @set = OptionSet.find(params[:id])
    begin 
      flash[:success] = @set.destroy && "Option set deleted successfully." 
    rescue
      if $!.is_a?(InvalidAssociationDeletionError)
        flash[:error] = "You can't delete option set '#{@set.name}' because one or more responses are associated with it."
      else
        flash[:error] = $!.to_s
      end
    end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  def update; crupdate; end

  private
    def crupdate
      action = params[:action]
      @set = action == "create" ? OptionSet.for_mission(current_mission).new : OptionSet.find(params[:id])
      begin
        @set.update_attributes!(params[:option_set])
        flash[:success] = "Option set #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid, InvalidAssociationDeletionError
        @set.errors.add(:base, $!.to_s) if $!.is_a?(InvalidAssociationDeletionError)
        render_form
      end
    end
    
    def render_form
      @options = restrict(Option).all
      render(:form)
    end
end
