# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
class BroadcastsController < ApplicationController
  
  def index
    @broadcasts = load_objects_with_subindex(Broadcast)
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
