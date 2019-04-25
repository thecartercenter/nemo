class WelcomeController < ApplicationController
  include ReportEmbeddable
  include ResponseIndexable

  # Don't need to authorize since we manually redirect to login if no user.
  # This is because anybody is 'allowed' to see the root and letting the auth system handle things
  # leads to nasty messages and weird behavior. We merely redirect because otherwise the page would be blank
  # and not very interesting.
  # We also skip the check for unauthorized because who cares if someone sees it.
  skip_authorization_check only: %i[index unauthorized]

  # number of rows in the stats blocks
  STAT_ROWS = 3

  # shows a series of blocks with info about the app
  def index
    return redirect_to(login_path) unless current_user

    if current_mission
      # Dashboard has no title.
      @dont_print_title = true
      dashboard_index
    elsif admin_mode?
      render :admin
    else
      render :no_mission
    end
  end

   # map info window
  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:read, @response)
    render(layout: false)
  end

  def unauthorized
  end

  private

  def dashboard_index
    # we need to check for a cache fragment here because some of the below fetches are not lazy
    @cache_key = [
      # we include the locale in the cache key so the translations are correct
      I18n.locale.to_s,

      # obviously we include this
      Response.per_mission_cache_key(current_mission),

      # we include assignments in the cache key since users show up in low activity etc.
      # if a user gets removed or added to the mission, that should show up
      # but we don't include user's in the cache key since users get updated every request
      # and that would defeat the purpose
      Assignment.per_mission_cache_key(current_mission)
    ].join("-")

    # get a relation for accessible responses
    accessible_responses = Response.accessible_by(current_ability)

    # load objects for the view
    @responses = accessible_responses.with_basic_assoc.with_basic_answers.latest_first
    @responses = @responses.paginate(page: 1, per_page: 20)

    # total responses for this mission
    @total_response_count = accessible_responses.count

    # unreviewed response count
    @unreviewed_response_count = accessible_responses.unreviewed.count

    # do the non-lazy loads inside these blocks so they don't run if we get a cache hit
    unless fragment_exist?(@cache_key + "/js_init")
      # get location answers
      location_answers = Answer.location_answers_for_mission(current_mission, current_user)

      @location_answers_count = location_answers.total_entries
      @location_answers = location_answers.map { |a| [a.response_id, a.latitude, a.longitude] }
    end

    unless fragment_exist?(@cache_key + "/stat_blocks")
      # responses by form (top N most popular)
      @responses_by_form = Response.per_form(accessible_responses, STAT_ROWS)

      # responses per user
      @responses_per_user = User.sorted_enumerator_response_counts(current_mission, STAT_ROWS)
    end

    # get list of all reports for the mission, for the dropdown
    @reports = Report::Report.accessible_by(current_ability).by_name

    prepare_report

    # render JSON if ajax request
    if request.xhr?
      data = {
        recent_responses: render_to_string(partial: "recent_responses"),
        response_locations: {
          answers: @location_answers,
          count: @location_answers_count
        },
        report_stats: render_to_string(partial: "report_stats")
      }
      render json: data
    else
      render(:dashboard)
    end
  end

  def prepare_report
    # if report id given, load that else use most popular
    if !params[:report_id].blank?
      @report = Report::Report.find(params[:report_id])
    else
      @report = Report::Report.accessible_by(current_ability).by_popularity.first
    end

    if @report
      # Make sure no funny business!
      authorize!(:read, @report)

      # We don't run the report, that will happen on an ajax call.
      build_report_data(read_only: true, embedded_mode: true)
    end
  end
end
