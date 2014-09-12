class BroadcastsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  # this method is special
  skip_load_and_authorize_resource :only => :new_with_users

  def index
    # apply pagination
    @broadcasts = @broadcasts.paginate(:page => params[:page], :per_page => 50)
  end

  def new
    flash[:success] = t("broadcast.instructions")

    # redirect to the users index, but don't worry about preserving the page number
    redirect_to(users_url)
  end

  # Displays a new broadcast form with the given recipients.
  # @param [Hash] selected A Hash user ids as keys, referring to recipients of the broadcast.
  def new_with_users
    # load the user objects
    users = User.accessible_by(current_ability).where(:id => params[:selected].keys).all

    # raise error if no valid users (this should be impossible)
    raise "no users given" if users.empty?

    # create a new Broadcast
    @broadcast = Broadcast.accessible_by(current_ability).new(:recipients => users)

    # call authorize so no error
    authorize!(:create, @broadcast)

    begin
      # get credit balance
      @balance = Smser.check_balance
    rescue NotImplementedError
      # don't need to do anything here
    rescue
      # log all other errors
      logger.error("SMS balance request error: #{$!}")
    end

    set_medium_options
    render(:form)
  end

  def show
    # We need to include all medium options in case this is an old broadcast and the options have changed.
    @medium_options = Broadcast::MEDIUM_OPTIONS
    render(:form)
  end

  def create
    if @broadcast.save
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

  private

    def set_medium_options
      @medium_options = configatron.to_h[:outgoing_sms_adapter] ? Broadcast::MEDIUM_OPTIONS : Broadcast::MEDIUM_OPTIONS_WITHOUT_SMS
    end
end
