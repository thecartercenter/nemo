class OptionSetsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def index
    # add the included assocations
    @option_sets = @option_sets.with_associations
  end
  
  def new
    prepare_and_render_form
  end
  
  def edit
    prepare_and_render_form
  end

  def show
    prepare_and_render_form
  end

  def create
    create_or_update
  end
  
  def update
    create_or_update
  end

  def destroy
    begin 
      flash[:success] = @option_set.destroy && "Option set deleted successfully." 
    rescue
      if $!.is_a?(InvalidAssociationDeletionError)
        flash[:error] = "You can't delete option set '#{@option_set.name}' because one or more responses are associated with it."
      else
        flash[:error] = $!.to_s
      end
    end
    redirect_to(:action => :index)
  end

  private
    # creates/updates the option set
    def create_or_update
      begin
        @option_set.update_attributes!(params[:option_set])
        flash[:success] = "Option set #{params[:action]}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid, InvalidAssociationDeletionError
        @option_set.errors.add(:base, $!.to_s) if $!.is_a?(InvalidAssociationDeletionError)
        prepare_and_render_form
      end
    end
    
    # prepares objects for and renders the form template
    def prepare_and_render_form
      @options = Option.accessible_by(current_ability).all
      render(:form)
    end
end
