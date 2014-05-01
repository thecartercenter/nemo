module Concerns::ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  # notifies the webmaster of an error in production mode
  def notify_error(exception, options = {})
    if Rails.env == "production"
      begin
        AdminMailer.error(exception, session.to_hash, params, request.env, current_user).deliver
      rescue
        logger.error("ERROR SENDING ERROR NOTIFICATION: #{$!.to_s}: #{$!.message}\n#{$!.backtrace.to_a.join("\n")}")
      end
    end
    # still show error page unless requested not to
    raise exception unless options[:dont_re_raise]
  end

  def handle_access_denied(exception)
    # set flag for tests to check
    @access_denied = true

    # log to debug log
    Rails.logger.debug("ACCESS DENIED on #{exception.action} #{exception.subject.inspect} #{exception.message} " +
      "(Current Mission: #{current_mission.try(:name)}; Current Role: #{current_user.try(:role, current_mission)})")

    # if not logged in, offer a login page
    if !current_user
      # don't put an error message if the request was for the home page
      flash[:error] = I18n.t("unauthorized.must_login") unless request.path == "/"
      redirect_to_login

    # else if there was just a mission change, we need to handle specially
    elsif params[:missionchange]
      # if the request was a CRUD, try redirecting to the index, or root if no permission
      if Ability::CRUD.include?(exception.action) && current_ability.can?(:index, exception.subject.class)
        redirect_to(:controller => controller_name, :action => :index)
      else
        redirect_to(mission_root_url)
      end

    # else if this is not an html request, render an empty 401 (unauthorized).
    elsif !request.format.html?
      render(:nothing => true, :status => 401)

    # else redirect to welcome page with error
    else
      redirect_to(root_url, :flash => { :error => exception.message })
    end
  end
end