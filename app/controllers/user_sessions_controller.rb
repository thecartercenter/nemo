class UserSessionsController < ApplicationController
  
  def new
    @title = "Login"
    @user_session = UserSession.new
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      # reset the perishable token for security's sake
      @user_session.user.reset_perishable_token!
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
    Subindex.clear_all(session)
    redirect_to(:action => :logged_out)
  end
  
  def logged_out
    @title = "Logged Out"
  end
end
