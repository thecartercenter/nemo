class OptionSetsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def index
    # get the total entries before adding the big joins
    total = @option_sets.count

    # add the included assocations and order
    @option_sets = @option_sets.with_assoc_counts_and_published(current_mission).by_name

    # paginate all on one page for now. we specify the total enteries so that the autogen'd count query isn't huge
    @option_sets = @option_sets.paginate(:page => 1, :per_page => 10000000, :total_entries => total)

    # now we apply .all so that any .empty? or .count calls in the template don't cause more queries
    @option_sets = @option_sets.all
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
