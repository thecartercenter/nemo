class BroadcastsController < ApplicationController
  include Searchable # Searches users

  # authorization via cancan
  load_and_authorize_resource

  # this method is special
  skip_load_and_authorize_resource only: :new_with_users

  def index
    @broadcasts = @broadcasts.
      manual_only.
      includes(:broadcast_addressings).
      paginate(page: params[:page], per_page: 50).
      order(created_at: :desc)
  end

  def new
    @broadcast = Broadcast.accessible_by(current_ability).new
    authorize!(:create, @broadcast)

    prep_form_vars
    render(:form)
  end

  # Displays a new broadcast form with the given recipients.
  # If params[:selected] is given, it is a hash with user ids as keys,
  # referring to recipients of the broadcast.
  # If params[:select_all] is given without params[:search],
  # it means the broadcast should be sent to all users in the system.
  # If params[:search] is given along with params[:select_all],
  # that search should be applied to obtain recipients.
  def new_with_users
    # We default to this since it is usually the case.
    # It will be overridden if select_all is given without search.
    recipient_selection = "specific"

    @broadcast = Broadcast.accessible_by(current_ability).new
    users = User.accessible_by(current_ability).with_assoc.by_name

    if params[:select_all].present?
      if params[:search].present?
        @broadcast.recipient_users = apply_search(User, users)
        @broadcast.recipient_selection = "specific"
      else
        @broadcast.recipient_selection = "all_users"
      end
    else
      @broadcast.recipient_users = users.where(id: params[:selected].keys)
      @broadcast.recipient_selection = "specific"
    end

    authorize!(:create, @broadcast)
    prep_form_vars
    render(:form)
  end

  def show
    # We need to include all medium options in case this is an old broadcast and the options have changed.
    @medium_options = Broadcast::MEDIUM_OPTIONS
    render(:form)
  end

  def create
    if @broadcast.save
      @broadcast.deliver
      if @broadcast.send_errors
        flash[:error] = t("broadcast.send_error")
      else
        flash[:success] = t("broadcast.send_success")
      end
      redirect_to(broadcast_url(@broadcast))
    else
      prep_form_vars
      render(:form)
    end
  end

  # Returns a JSON array of Users and UserGroups matching params[:q].
  # Returns a maximum of 10 users and 10 groups.
  # User should refine search if they don't see what they're looking for at first.
  # Also returns an indication of if there are more results available via pagination.
  def possible_recipients
    @users = User.assigned_to(current_mission).by_name
    @groups = UserGroup.for_mission(current_mission).by_name

    if params[:q].present?
      @users = @users.name_matching(params[:q])
      @groups = @groups.name_matching(params[:q])
    end

    @users = @users.paginate(page: params[:page], per_page: 5)
    @groups = @groups.paginate(page: params[:page], per_page: 5)

    users_fetched = @users.total_pages > params[:page].to_i
    groups_fetched = @groups.total_pages > params[:page].to_i

    @recipients = []
    [@groups, @users].each do |set|
      set.each { |u| @recipients << Recipient.new(object: u) }
    end


    render json: {
      results: ActiveModel::ArraySerializer.new(@recipients, each_serializer: RecipientSerializer),
      pagination: { more: (users_fetched || groups_fetched) }
    }
  end

  private

  def prep_form_vars
    @medium_options = configatron.to_h[:outgoing_sms_adapter] ?
      Broadcast::MEDIUM_OPTIONS : Broadcast::MEDIUM_OPTIONS_WITHOUT_SMS
    @users = User.accessible_by(current_ability).all
  end

  def broadcast_params
    params.require(:broadcast).permit(:subject, :body, :medium, :send_errors, :which_phone,
      :mission_id, :recipient_selection, recipient_ids: [])
  end
end
