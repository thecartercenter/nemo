class OptionSetsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def index
    # add the included assocations
    @option_sets = @option_sets.with_associations
  end
  
  def new
    # we only need the partial if it's an ajax request
    if ajax_request?
      render(:partial => 'form')
    else
      render(:form)
    end
  end
  
  def edit
    render(:form)
  end

  def show
    render(:form)
  end

  def create
    create_or_update
  end
  
  def update
    @option_set.assign_attributes(params[:option_set])
    create_or_update
  end

  def destroy
    destroy_and_handle_errors(@option_set, :but_first => :check_associations)
    redirect_to(:action => :index)
  end

  private
    # creates/updates the option set
    def create_or_update
      begin
        @option_set.save!
        
        # if this is an ajax request, we just render the option set's id
        if ajax_request?
          render(:json => @option_set.id)
        else
          set_success_and_redirect(@option_set)
        end
      rescue ActiveRecord::RecordInvalid, DeletionError
        @option_set.errors.add(:base, $!.to_s) if $!.is_a?(DeletionError)
        
        # if this is an ajax request, we just render the form partial
        if ajax_request?
          render(:partial => 'form')
        else
          render(:form)
        end
      end
    end
end
