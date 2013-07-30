# handles the dashboard view. plural name just because of Rails convention.
class DashboardController < ApplicationController
  def show
    authorize!(:view, :dashboard)
    @dont_print_title = true
    
    # load objects for the view
    @responses = Response.accessible_by(current_ability).with_basic_assoc.with_basic_answers.limit(20)
    
    # get location answers
    @location_answers = Answer.location_answers_for_mission(current_mission)
    
    # get list of all reports for the mission
    @reports = Report::Report.accessible_by(current_ability).by_name
    
    # get the most popular report
    @report = Report::Report.accessible_by(current_ability).by_popularity.first
  end
  
  # map info window
  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:view, @response)
    render(:layout => false)
  end
end