class OptionSetsController < ApplicationController
  include StandardImportable

  # authorization via cancan
  load_and_authorize_resource

  def index
    # get the total entries before adding the big joins
    total = @option_sets.count

    # add the included assocations and order
    @option_sets = @option_sets.with_assoc_counts_and_published(current_mission).by_name

    # paginate all on one page for now. we specify the total entries so that the autogen'd count query isn't huge.
    # we still bother to call pagination so that the table header works
    @option_sets = @option_sets.paginate(:page => 1, :per_page => 10000000, :total_entries => total)

    # now we apply .all so that any .empty? or .count calls in the template don't cause more queries
    @option_sets = @option_sets.all

    load_importable_objs
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
    # assign attribs and validate now so that normalization runs before authorizing and saving
    @option_set.assign_attributes(params[:option_set])
    @option_set.valid?

    # authorize special abilities
    authorize!(:update_core, @option_set) if @option_set.core_changed?
    authorize!(:add_options, @option_set) if @option_set.options_added?
    authorize!(:remove_options, @option_set) if @option_set.options_removed?
    authorize!(:reorder_options, @option_set) if @option_set.positions_changed?

    create_or_update
  end

  def destroy
    destroy_and_handle_errors(@option_set)
    redirect_to(index_url_with_page_num)
  end

  # makes a copy of the option set that can be edited without affecting the original
  def clone
    begin
      cloned = @option_set.replicate

      # save the cloned obj id so that it will flash
      flash[:modified_obj_id] = cloned.id

      flash[:success] = t("option_set.clone_success", :name => @option_set.name)
    rescue
      flash[:error] = t("option_set.clone_error", :msg => $!.to_s)
    end
    redirect_to(index_url_with_page_num)
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
        flash.now[:error] = I18n.t('activerecord.errors.models.option_set.general')
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
