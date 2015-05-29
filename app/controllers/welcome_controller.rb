class WelcomeController < ApplicationController
  include ReportEmbeddable

  # Don't need to authorize since we manually redirect to login if no user.
  # This is because anybody is 'allowed' to see the root and letting the auth system handle things
  # leads to nasty messages and weird behavior. We merely redirect because otherwise the page would be blank
  # and not very interesting.
  # We also skip the check for unauthorized because who cares if someone sees it.
  skip_authorization_check :only => [:index, :unauthorized]

  # number of rows in the stats blocks
  STAT_ROWS = 3

  # shows a series of blocks with info about the app
  def index
    return redirect_to(login_path) unless current_user

    # we set this because there is no title on the page
    @dont_print_title = true

    if current_mission
      # we need to load the report outside the cache block b/c it's included in the cache key
      # if report id given, load that
      if !params[:report_id].blank?
        @report = Report::Report.find(params[:report_id])
      else
        # else load the most popular report
        @report = Report::Report.accessible_by(current_ability).by_popularity.first
      end

      # we need to check for a cache fragment here because some of the below fetches are not lazy
      @cache_key = [
        # we include the locale in the cache key so the translations are correct
        I18n.locale.to_s,

        # obviously we include this
        Response.per_mission_cache_key(current_mission),

        # we include assignments in the cache key since users show up in low activity etc. if a user gets removed or added to the mission, that should show up
        # but we don't include user's in the cache key since users get updated every request and that would defeat the purpose
        Assignment.per_mission_cache_key(current_mission),

        # we include the report in case the report definition changes
        @report.try(:cache_key) || 'no-report'
      ].join('-')

      # get a relation for accessible responses
      accessible_responses = Response.accessible_by(current_ability)

      # load objects for the view
      @responses = accessible_responses.with_basic_assoc.with_basic_answers.paginate(:page => 1, :per_page => 20)

      # total responses for this mission
      @total_response_count = accessible_responses.count

      # unreviewed response count
      @unreviewed_response_count = accessible_responses.unreviewed.count

      # do the non-lazy loads inside these blocks so they don't run if we get a cache hit
      unless fragment_exist?(@cache_key + '/js_init')
        # get location answers
        # TODO refactor user argument
        @location_answers = Answer.location_answers_for_mission(current_mission, current_user.role(current_mission) == 'observer' ? current_user : nil)
      end

      unless fragment_exist?(@cache_key + '/stat_blocks')
        # responses by form (top N most popular)
        @responses_by_form = Response.per_form(accessible_responses, STAT_ROWS)

        # responses per user
        @responses_per_user = User.sorted_observer_response_counts(current_mission, STAT_ROWS)
      end

      # get list of all reports for the mission, for the dropdown
      @reports = Report::Report.accessible_by(current_ability).by_name

      unless fragment_exist?(@cache_key + '/report_pane')
        prepare_report
      end
    end

    # render without layout if ajax request
    render(:layout => !request.xhr?)
  end

   # map info window
  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:view, @response)
    render(:layout => false)
  end

  # loads the specified report when chosen from the dropdown menu
  def report_update
    @report = Report::Report.find(params[:id])
    prepare_report
    render(:json => {
      :title => render_to_string(:partial => 'report_pane_title'),
      :main => render_to_string(:partial => 'reports/main')
    })
  end

  def unauthorized
  end

  private
    def prepare_report
      unless @report.nil?
        authorize!(:view, @report)
        run_and_handle_errors
        build_report_data(:read_only => true, :dont_set_title => true)
      end
    end

end
