class PasswordResetsController < ApplicationController
  
  before_filter(:load_user_using_perishable_token, :only => [:edit, :update])

  def new
    @title = "Reset Password"
  end  

  # when the user returns and enters their new password
  def edit
    @title = "Reset Password"
  end

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
