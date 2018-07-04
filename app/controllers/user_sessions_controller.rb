class UserSessionsController < ApplicationController

  helper_method :captcha_required?

  # don't need to authorize here (except for destroy action) because anyone can see log in page
  skip_authorization_check

  before_action(:ensure_logged_out, :only => [:new, :destroy, :logged_out])

  def new
    @user_session = UserSession.new
  end

  def create
    # reset the session for security purposes
    reset_session_preserving_return_to

    @user_session = UserSession.new(user_session_params.to_h)

    # if the save is successful, the user is logged in automatically
    if allow_login && @user_session.save
      post_login_housekeeping
    else
      flash[:error] = @user_session.errors.full_messages.join(",")
      redirect_to(:action => :new)
    end
  end

  def destroy
    forget_location
    redirect_to(logged_out_url)
  end

  # shows a simple 'you are logged out' page
  def logged_out
  end

  def login_confirmation
    authorize!(:confirm_login, UserSession)

    @user_session = UserSession.new
  end

  def process_login_confirmation
    authorize!(:confirm_login, UserSession)

    params[:user_session][:login] = current_user.login

    @user_session = UserSession.new(user_session_params)

    # if the save is successful, the user is logged in automatically
    if allow_login && @user_session.save
      post_login_housekeeping
    else
      flash[:error] = @user_session.errors.full_messages.join(",")
      redirect_to(login_confirmation_url)
    end
  end

  # Special route, test only, used by feature specs to simulate user login.
  def test_login
    return render plain: 'TEST MODE ONLY', status: 403 unless Rails.env.test?
    @user = User.find(params[:user_id])
    UserSession.create(@user)
    post_login_housekeeping(dont_redirect: true)

    # We redirect to user profile instead of dashboard because dashboard is slower to load and is not needed.
    redirect_to user_path(@user, locale: 'en', mode: 'm', mission_name: @user.best_mission.compact_name)
  end

  private

    def user_session_params
      params.require(:user_session).permit(:login, :password)
    end

    def allow_login
      if captcha_required?
        Rails.logger.info "Verifying reCAPTCHA submission for #{request.remote_ip}"
        verify_recaptcha(model: @user_session)
      else
        true
      end
    end

    def captcha_required?
      !!request.env['elmo.captcha_required']
    end
end
