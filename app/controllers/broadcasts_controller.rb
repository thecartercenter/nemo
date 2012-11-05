class BroadcastsController < ApplicationController
  
  def index
    @broadcasts = apply_filters(Broadcast)
  end
  
  def new
    flash[:success] = "To send a broadcast, first select the recipients below, and then click 'Send Broadcast'."
    redirect_to(users_path)
  end
  
  # Displays a new broadcast form with the given recipients.
  # @param [Hash] selected A Hash user ids as keys, referring to recipients of the broadcast.
  def new_with_users
    # load the user objects
    users = params[:selected].keys.collect{|id| User.find_by_id(id)}.compact
        
    # raise error if no valid users (this should be impossible)
    raise "No valid users given." if users.empty?
    
    # create a new Broadcast
    @broadcast = Broadcast.for_mission(current_mission).new(:recipients => users)

    begin
      # get credit balance
      @balance = Smser.check_balance  
    rescue
      # log all errors
      logger.error("SMS balance request error: #{$!}")
      
      # set @balance to nil if error
      @balance = nil
    end
    
    render(:form)
  end
  
  def show
    @broadcast = Broadcast.find(params[:id])
    render(:form)
  end
  
  def create
    @broadcast = Broadcast.for_mission(current_mission).new(params[:broadcast])
    if @broadcast.save
      if @broadcast.send_errors
        flash[:error] = "Broadcast was sent, but with some errors (see below)."
      else
        flash[:success] = "Broadcast sent successfully."
      end
      redirect_to(broadcast_path(@broadcast))
    else
      render(:form)
    end
  end
end
