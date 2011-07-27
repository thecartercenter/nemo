class OptionSetsController < ApplicationController
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "OptionSet", params[:page])
    # get the option sets
    @sets = OptionSet.sorted(@subindex.params)
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

#  def destroy
#    @option = Option.find(params[:id])
#    begin flash[:success] = @option.destroy && "Option deleted successfully." rescue flash[:error] = $!.to_s end
#    redirect_to(:action => :index)
#  end
#  
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
