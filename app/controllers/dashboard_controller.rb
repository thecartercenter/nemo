# handles the dashboard view. plural name just because of Rails convention.
class DashboardController < ApplicationController
  # number of rows in the stats blocks
  STAT_ROWS = 3
  
  def show
    authorize!(:view, :dashboard)
    @dont_print_title = true

    # get a relation for accessible responses
    accessible_responses = Response.accessible_by(current_ability)
    
    # load objects for the view
    @responses = accessible_responses.with_basic_assoc.with_basic_answers.limit(20)
    
    # get location answers
    @location_answers = Answer.location_answers_for_mission(current_mission)
    
    # get list of all reports for the mission
    @reports = Report::Report.accessible_by(current_ability).by_name
    
    # get the most popular report
    @report = Report::Report.accessible_by(current_ability).by_popularity.first
    
    # get the number of responses in recent period
    @recent_responses_count = Response.recent_count(accessible_responses)
    
    # total responses for this mission
    @total_response_count = accessible_responses.count
    
    # unreviewed response count
    @unreviewed_response_count = accessible_responses.unreviewed.count
    
    # responses by form (top N most popular)
    @responses_by_form = Response.per_form(accessible_responses, STAT_ROWS)
  end
  
  # map info window
  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:view, @response)
    render(:layout => false)
  end
  
  # rebuilds the report header when a new report is chosen
  def report_header
    # load just report, no associations, and don't run it. that happens in reports controller.
    @report = Report::Report.find(params[:id])
    authorize!(:view, @report)
    render(:partial => 'report_header')
  end
end