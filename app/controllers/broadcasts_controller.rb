class BroadcastsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  # this method is special
  skip_load_and_authorize_resource only: :new_with_users

  def index
    # apply pagination
    @broadcasts = @broadcasts.paginate(page: params[:page], per_page: 50)
  end

  def new
    flash[:success] = t("broadcast.instructions")

    # redirect to the users index, but don't worry about preserving the page number
    redirect_to(users_url)
  end

  # Displays a new broadcast form with the given recipients.
  # @param [Hash] selected A Hash user ids as keys, referring to recipients of the broadcast.
  def new_with_users
    if params[:select_all].present?
      if params[:search].present?
        users = User.accessible_by(current_ability).with_assoc.by_name
        begin
          users = User.do_search(users, params[:search]).to_a
        rescue Search::ParseError
          flash.now[:error] = $!.to_s
          @search_error = true
        end
      else
        users = User.accessible_by(current_ability).to_a
      end
    else
      users = User.accessible_by(current_ability).where(id: params[:selected].keys).to_a
    end
    raise "no users given" if users.empty? # This should be impossible

    @broadcast = Broadcast.accessible_by(current_ability).new(recipients: users)

    authorize!(:create, @broadcast)

    if @broadcast.no_possible_recipients?
      flash[:error] = t('broadcast.no_possible_recipients')
      redirect_to(users_path)
    else
      begin
        @balance = Sms::Broadcaster.check_balance
      rescue NotImplementedError
        # don't need to do anything here
      rescue
        @balance = :failed
        logger.error("SMS balance request error: #{$!}")
      end

      set_medium_options
      render(:form)
    end
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
      set_medium_options
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
      set.each { |u| @recipients << BroadcastRecipient.new(object: u) }
    end


    render json: {
      results: ActiveModel::ArraySerializer.new(@recipients, each_serializer: BroadcastRecipientSerializer),
      pagination: { more: (users_fetched || groups_fetched) }
    }
  end

  private

    def set_medium_options
      @medium_options = configatron.to_h[:outgoing_sms_adapter] ? Broadcast::MEDIUM_OPTIONS : Broadcast::MEDIUM_OPTIONS_WITHOUT_SMS
    end

    def broadcast_params
      params.require(:broadcast).permit(:subject, :body, :medium, :send_errors, :which_phone, :mission_id, recipient_ids: [])
    end
end
