class UserSessionsController < ApplicationController
  
  def new
    @title = "Login"
    @user_session = UserSession.new
  end
  
  def create
    reset_session
    @user_session = UserSession.new(params[:user_session])
    
    # if the save is successful, the user is logged in automatically
    if @user_session.save
      
      # do post login housekeeping
      return unless post_login_housekeeping
      
      flash[:success] = "Login successful"
      redirect_back_or_default(root_path)
    else
      flash[:error] = @user_session.errors.full_messages.join(",")
      redirect_to(:action => :new)
    end
  end
  
  def destroy
    @user_session = UserSession.find  
    @user_session.destroy
    forget_location
    redirect_to(:action => :logged_out)
  end
  
  def logged_out
    @title = "Logged Out"
  end
end
