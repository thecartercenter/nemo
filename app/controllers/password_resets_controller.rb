class PasswordResetsController < ApplicationController
  include PasswordResettable

  # Don't need to authorize for any of these because they're for logged out users
  skip_authorization_check

  before_action(:ensure_logged_out)
  before_action(:load_user_using_perishable_token, only: [:edit, :update])

  # When the user requests a password reset
  def new
    @password_reset = PasswordReset.new
  end

  # When the user returns and enters their new password
  def edit
  end

  # Sends the password reset instructions
  def create
    @password_reset = PasswordReset.new(password_reset_params)
    if (users = @password_reset.matches).any?
      if users.count > 1
        flash.now[:error] = t("password_reset.multiple_accounts")
        render :new
      elsif (user = users.first).email.blank?
        flash.now[:error] = t("password_reset.no_associated_email")
        render :new
      else
        reset_password(user, notify_method: "email")
        flash[:success] = t("password_reset.check_email")
        redirect_to(login_url)
      end
    else
      flash.now[:error] = t("password_reset.user_not_found")
      render :new
    end
  end

  # Changes the password
  def update
    User.ignore_blank_passwords = false
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    if @user.save
      User.ignore_blank_passwords = true

      # If we get this far, the user has been logged in.
      post_login_housekeeping

      flash[:success] = t("password_reset.success")
    else
      @user.password = nil
      @user.password_confirmation = nil
      render(action: :edit)
    end
  end

  private

  # Loads a user using a perishable token stored in params[:id]
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:error] = t("password_reset.token_not_found")
      redirect_to(login_url)
    end
  end

  def password_reset_params
    params.require(:password_reset).permit(:identifier).to_h.symbolize_keys
  end
end
