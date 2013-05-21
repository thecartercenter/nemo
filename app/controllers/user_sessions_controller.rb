class UserSessionsController < ApplicationController
  # don't need to authorize here (except for destroy action) because anyone can see log in page
  skip_authorization_check
  
  def new
    @title = "Login"
    @user_session = UserSession.new
  end
  
  def create
    # reset the session for security purposes
    reset_session_preserving_return_to
    
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
    @user_session.destroy if @user_session
    forget_location
    redirect_to(logged_out_path)
  end
  
  # shows a simple 'you are logged out' page
  def logged_out
    @title = "Logged Out"
  end
end
