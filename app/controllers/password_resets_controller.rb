class PasswordResetsController < ApplicationController
  # don't need to authorize for any of these because they're for logged out users
  skip_authorization_check

  # load the user using the perishable token rather than session
  before_filter(:load_user_using_perishable_token, :only => [:edit, :update])

  # when the user requests a password reset
  def new
    @password_reset = PasswordReset.new
  end

  # when the user returns and enters their new password
  def edit
  end

  # sends the password reset instructions
  def create
    email = params[:password_reset][:email].strip
    if email.present? && @user = User.where(:email => email).first
      @user.deliver_password_reset_instructions!
      flash[:success] = t("password_reset.check_email")
      redirect_to(login_url)
    else
      flash[:error] = t("password_reset.user_not_found")
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

      flash[:success] = t("password_reset.success")

      # use redirect_back_or_default to preserve the original path, if appropriate
      redirect_back_or_default(root_url)
    else
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
        flash[:error] = t("password_reset.token_not_found")
        redirect_to(login_url)
      end
    end
end
