class BroadcastsController < ApplicationController
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Broadcast", params[:page])
    # get the broadcasts
    @broadcasts = Broadcast.sorted(@subindex.params)
  end
  def new
    flash[:success] = "To send a broadcast, first select the recipients below, and then click 'Send Broadcast'."
    redirect_to(users_path)
  end
  def new_with_users
    # load the user objects
    users = params[:selected].keys.collect{|id| User.find_by_id(id)}.compact

    # raise error if no valid users (this should be impossible)
    raise "No valid users given." if users.empty?
    
    # create a new Broadcast
    @broadcast = Broadcast.new(:recipients => users)
    
    # render new action
    render_new
  end
  def show
    @broadcast = Broadcast.find(params[:id])
  end
  def create
    @broadcast = Broadcast.new(params[:broadcast])
    if @broadcast.save
      if @broadcast.send_errors
        flash[:error] = "Broadcast was sent, but with some errors (see below)."
      else
        flash[:success] = "Broadcast sent successfully."
      end
      redirect_to(broadcast_path(@broadcast))
    else
      render_new
    end
  end
  
  private
    def render_new
      @title = "Send Broadcast"
      render(:action => :new)
    end
end
