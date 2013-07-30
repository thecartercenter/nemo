# handles the dashboard view. plural name just because of Rails convention.
class DashboardController < ApplicationController
  def show
    authorize!(:view, :dashboard)
    @dont_print_title = true
    
    # load objects for the view
    @responses = Response.accessible_by(current_ability).includes(:location_answers).limit(20)
  end
end