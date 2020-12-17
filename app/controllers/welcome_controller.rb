# frozen_string_literal: true

class WelcomeController < ApplicationController
  # Don't need to authorize since we manually redirect to login if no user.
  # This is because anybody is 'allowed' to see the root and letting the auth system handle things
  # leads to nasty messages and weird behavior. We merely redirect because otherwise the page would be blank
  # and not very interesting.
  # We also skip the check for unauthorized because who cares if someone sees it.
  skip_authorization_check only: %i[index unauthorized]

  def index
    return redirect_to(login_path) unless current_user

    # Admin mode or the eventual library should be its own controller. It may seem weird
    # that we are not checking permissions here but there is code in
    # app/controllers/concerns/application_controller/authorization.rb
    # that protects admin mode. Not ideal but fine for now.
    if admin_mode?
      render(:admin)
    else
      render(:no_mission)
    end
  end

  def unauthorized
  end
end
