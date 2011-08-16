class OptionSetsController < ApplicationController
  def index
    @sets = load_objects_with_subindex(OptionSet)
  end
  
  def new
    @set = OptionSet.new
  end
  
  def edit
    @set = OptionSet.find(params[:id])
  end

  def show
    @set = OptionSet.find(params[:id])
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
      @set = action == "create" ? OptionSet.new : OptionSet.find(params[:id], :include => OptionSet.default_eager)
      begin
        @set.update_attributes!(params[:option_set])
        flash[:success] = "Option set #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid, InvalidAssociationDeletionError
        @set.errors.add(:base, $!.to_s) if $!.is_a?(InvalidAssociationDeletionError)
        render(:action => action == "create" ? :new : :edit)
      end
    end
end
