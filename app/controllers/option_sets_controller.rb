class OptionSetsController < ApplicationController
  include StandardImportable
  include Parameters

  before_action :arrayify_attribs, only: [:create, :update]

  # authorization via cancan
  load_and_authorize_resource
  skip_authorization_check only: :child_nodes

  def index
    # get the total entries before adding the big joins
    total = @option_sets.count

    # add the included assocations and order
    @option_sets = @option_sets.includes(:root_node).by_name

    # paginate all on one page for now. we specify the total entries so that the autogen'd count query isn't huge.
    # we still bother to call pagination so that the table header works
    @option_sets = @option_sets.paginate(page: 1, per_page: 10000000, total_entries: total)

    # now we apply .all so that any .empty? or .count calls in the template don't cause more queries
    @option_sets = @option_sets.to_a

    # Avoid N+1 for option names.
    OptionSet.preload_top_level_options(@option_sets)

    load_importable_objs
  end

  def new
    # we only need the partial if it's an ajax request
    if request.xhr?
      @option_set.adding_to_question_type = params[:adding_to_question_type]

      params[:modal_mode] = true
      render(partial: "form")
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

  def export
    @headers = @option_set.headers_for_export
    @rows = @option_set.arrange_as_rows

    render xlsx: "export", filename: "#{@option_set.name}.xlsx"
  end

  # always via AJAX
  def create
    @option_set.is_standard = true if current_mode == "admin"
    OptionSet.transaction do
      create_or_update
    end
  end

  # always via AJAX
  def update
    # we use a transaction because populate_from_json requests it
    OptionSet.transaction do
      @option_set.assign_attributes(option_set_params) # Quotes vs symbol is important here.

      # validate now so that normalization runs before authorizing and saving
      # We raise if there is an error since validation should happen client side.
      raise ActiveRecord::RecordInvalid.new("Option set is invalid") unless @option_set.valid?

      # authorize special abilities
      authorize!(:update_core, @option_set) if @option_set.core_changed?
      authorize!(:add_options, @option_set) if @option_set.options_added?
      authorize!(:remove_options, @option_set) if @option_set.options_removed?
      authorize!(:reorder_options, @option_set) if @option_set.ranks_changed?

      create_or_update
    end
  end

  def destroy
    destroy_and_handle_errors(@option_set)
    redirect_to(index_url_with_context)
  end

  # Returns the options available at the node in the option tree specified by the given node
  def child_nodes
    @children = OptionNode.find(params[:node_id]).sorted_children
    render(layout: false)
  end

  # makes a copy of the option set that can be edited without affecting the original
  def clone
    begin
      cloned = @option_set.replicate(mode: :clone)

      # save the cloned obj id so that it will flash
      flash[:modified_obj_id] = cloned.id

      flash[:success] = t("option_set.clone_success", name: @option_set.name)
    rescue
      flash[:error] = t("option_set.clone_error", msg: $!.to_s)
    end
    redirect_to(index_url_with_context)
  end

  def condition_form_view
    option_node = OptionNode.find_by_id(params[:node_id]) # null if not found instead of throwing exception
    option_node ||= @option_set.root_node
    render json: OptionNodeConditionViewSerializer.new(option_node)
  end

  private

  # Converts level_names and children (recursively) attribs hashes to arrays.
  def arrayify_attribs
    arrayify_hash_and_children(params["option_set"], "level_names")
    arrayify_hash_and_children(params["option_set"], "children_attribs")
  end

  def arrayify_hash_and_children(hash, key)
    return unless hash[key].is_a?(Hash)
    hash[key] = hash[key].values
    hash[key].each do |value|
      arrayify_hash_and_children(value, key) if value[key].is_a?(Hash)
    end
  end

  # creates/updates the option set
  def create_or_update
    begin
      @option_set.save!

      # set the flash, which will be shown when the next request is issued as expected
      # (not needed in modal mode)
      set_success(@option_set) unless params[:modal_mode]

      if params[:modal_mode]
        # render the option set's ID in json format
        render(json: @option_set.id.to_json)
      else
        # render where we should redirect
        render(json: option_sets_path.to_json)
      end

    # These shouldn't generally happen since the delete link is hidden in cases where options shouldn't be deleted.
    # Only remotely possible if answer arrives between when form rendered and submitted.
    # Also, we don't catch validation errors since they should be handled on client side.
    rescue DeletionError
      flash.now[:error] = $!.to_s
      render(partial: "form")
      raise ActiveRecord::Rollback # Rollback the transaction without re-raising the error.
    end
  end

  def option_set_params
    params.require(:option_set).permit(
      :name, :geographic, :allow_coordinates, :sms_guide_formatting, :multilevel,
      level_names: configatron.preferred_locales,
      children_attribs: permit_children(
        params[:option_set],
        key: :children_attribs,
        permitted: [
          :id,
          {
            option_attribs: [
              :id, :latitude, :longitude, :value,
              {name_translations: configatron.preferred_locales}
            ]
          }
        ]
      )
    )
  end
end
