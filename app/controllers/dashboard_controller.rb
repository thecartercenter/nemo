# handles the dashboard view. plural name just because of Rails convention.
class DashboardController < ApplicationController
  include ReportEmbeddable

  # number of rows in the stats blocks
  STAT_ROWS = 3
  
  def show
    authorize!(:view, :dashboard)
    @dont_print_title = true
    
    # we need to load the report outside the cache block b/c it's included in the cache key
    @report = Report::Report.accessible_by(current_ability).by_popularity.first
    
    # we need to check for a cache fragment here because some of the below fetches are not lazy
    @cache_key = Response.per_mission_cache_key(current_mission) + '-' + (@report.try(:cache_key) || 'no-report')
    
    unless fragment_exist?(@cache_key)
    
      # get a relation for accessible responses
      accessible_responses = Response.accessible_by(current_ability)
    
      # load objects for the view
      @responses = accessible_responses.with_basic_assoc.with_basic_answers.limit(20)
    
      # get location answers
      @location_answers = Answer.location_answers_for_mission(current_mission)
    
      # get list of all reports for the mission
      @reports = Report::Report.accessible_by(current_ability).by_name
    
      # get the number of responses in recent period
      @recent_responses_count = Response.recent_count(accessible_responses)
    
      # total responses for this mission
      @total_response_count = accessible_responses.count
    
      # unreviewed response count
      @unreviewed_response_count = accessible_responses.unreviewed.count
    
      # responses by form (top N most popular)
      @responses_by_form = Response.per_form(accessible_responses, STAT_ROWS)
      
      prepare_report
    end
  end
  
  # map info window
  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:view, @response)
    render(:layout => false)
  end
  
  # loads the specified report when chosen from the dropdown menu
  def report_pane
    @report = Report::Report.find(params[:id])
    prepare_report
    render(:partial => 'report_pane')
  end
  
  private
  
    def prepare_report
      authorize!(:view, @report)
      build_report_data(:read_only => true)
      run_and_handle_errors
    end
end