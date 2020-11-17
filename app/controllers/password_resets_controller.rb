# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  include PasswordResettable

  # Don't need to authorize for any of these because they're for logged out users
  skip_authorization_check

  before_action(:ensure_logged_out)
  before_action(:load_user_using_perishable_token, only: %i[edit update])

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
        render(:new)
      elsif (user = users.first).email.blank?
        flash.now[:error] = t("password_reset.no_associated_email")
        render(:new)
      else
        send_reset_password_instructions(user)
        flash[:success] = t("password_reset.check_email")
        redirect_to(login_url)
      end
    else
      flash.now[:error] = t("password_reset.user_not_found")
      render(:new)
    end
  end

  # Changes the password
  def update
    User.ignore_blank_passwords = false
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    # Don't log in automatically. This can create hard-to-find bugs if automatic login isn't working.
    if @user.save_without_session_maintenance
      if !@user.active?
        flash[:error] = t("password_reset.success_but_inactive")
        redirect_to(login_url)
      else
        # Log in the user explicitly
        UserSession.create!(login: @user.login, password: @user.password)
        post_login_housekeeping
        flash[:success] = t("password_reset.success")
      end
    else
      @user.password = nil
      @user.password_confirmation = nil
      render(action: :edit)
    end
  ensure
    User.ignore_blank_passwords = true
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
