class PasswordResetsController < ApplicationController
  # don't need to authorize for any of these because they're for logged out users
  skip_authorization_check
  
  # load the user using the perishable token rather than session
  before_filter(:load_user_using_perishable_token, :only => [:edit, :update])
  
  # when the user requests a password reset
  def new
    @title = "Reset Password"
  end  

  # when the user returns and enters their new password
  def edit
    @title = "Reset Password"
  end
  
  # sends the password reset instructions
  def create  
    @user = User.find_by_email(params[:email])  
    if @user  
      @user.deliver_password_reset_instructions!  
      flash[:success] = "Instructions to reset your password have been emailed to you. Please check your email."  
      redirect_to(login_path)
    else  
      flash[:error] = "No user was found with that email address"  
      redirect_to(:action => :new)
    end
  end
  
  # changes the password
  def update
    User.ignore_blank_passwords = false
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    
    if @user.save
      User.ignore_blank_passwords = true

      # if we get this far, the user has been logged in
      # so do post login housekeeping
      return unless post_login_housekeeping

      flash[:success] = "Password successfully updated."
      
      # use redirect_back_or_default to preserve the original path, if appropriate
      redirect_back_or_default(root_url)
    else
      @title = "Reset Password"
      @user.password = nil
      @user.password_confirmation = nil
      render(:action => :edit)  
    end  
  end  

  private
    # loads a user using a perishable token stored in params[:id]
    def load_user_using_perishable_token
      @user = User.find_using_perishable_token(params[:id])  
      unless @user
        flash[:error] = "We're sorry, but we could not locate your account. " +  
          "If you are having issues try copying and pasting the URL " +  
          "from your email into your browser or restarting the " +  
          "reset password process."  
        redirect_to(login_url)
      end
    end
end
