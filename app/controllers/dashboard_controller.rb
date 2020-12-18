# frozen_string_literal: true

class DashboardController < ApplicationController
  include ResponseIndexable
  include ReportEmbeddable

  STAT_ROWS = 3
  MAX_MAP_LOCATIONS = 1000

  # Manually checking this for now.
  skip_authorization_check only: %i[index]

  def index
    return redirect_to(responses_path) unless can?(:view, :dashboard)
    @dont_print_title = true
    accessible_responses = Response.accessible_by(current_ability)

    instance_variable_cache("@responses") do
      accessible_responses.with_basic_assoc.with_basic_answers.latest_first.paginate(page: 1, per_page: 20)
    end

    instance_variable_cache("@total_response_count") do
      accessible_responses.count
    end

    instance_variable_cache("@unreviewed_response_count") do
      accessible_responses.unreviewed.count
    end

    instance_variable_cache("@response_locations") do
      # This query should be reasonably fast. Tested on a mission with >3m answers and it was running
      # around 400ms. It's hard to do better than this without some kind of preprocessing.
      # Tried sorting by RANDOM(), slow. Tried Postgres' table sample methods, promising, but you can't
      # apply a where condition before the sample is taken, so you can't take a sample of just one
      # mission's answers. Bummer!
      # We use ResponseNode instead of Answer to avoid the unnecessary type check.
      ResponseNode.for_mission(current_mission)
        .with_coordinates.newest_first.limit(MAX_MAP_LOCATIONS)
        .pluck(:response_id, :latitude, :longitude)
    end

    instance_variable_cache("@responses_by_form") do
      Response.per_form(accessible_responses, STAT_ROWS)
    end

    instance_variable_cache("@recent_response_count", expires_in: 30.minutes) do
      Response.recent_count(Response.accessible_by(current_ability))
    end

    prep_report_data(load_report_id_from_params_or_session)

    # render JSON if ajax request
    if request.xhr?
      data = {
        recent_responses: render_to_string(partial: "recent_responses"),
        response_locations: @response_locations,
        stats: render_to_string(partial: "stats"),
        report_content: render_to_string(partial: "report_content")
      }
      render(json: data)
    else
      render(:dashboard)
    end
  end

  # Called via AJAX when the a new report is chosen.
  def report
    prep_report_data(params[:id])
    @report ? authorize!(:show, @report) : authorize!(:view, :dashboard)
    render(partial: "report")
  end

  def info_window
    @response = Response.with_basic_assoc.find(params[:response_id])
    authorize!(:read, @response)
    render(layout: false)
  end

  def unauthorized
  end

  private

  def prep_report_data(report_id)
    # get list of all reports for the mission, for the dropdown
    @reports = Report::Report.accessible_by(current_ability).by_name
    save_report_id_in_session(report_id)

    return if report_id.blank?
    @report = Report::Report.find(report_id)
    run_or_fetch_and_handle_errors
    prepare_frontend_data(embedded_mode: true)
  end

  def load_report_id_from_params_or_session
    # params[:rpid] may be empty string, and that is a valid value (no report) and should be returned
    params[:rpid] || session.dig(:rpid, current_mission.shortcode)
  end

  # report_id may be empty string, and that is a valid value and should still be saved.
  def save_report_id_in_session(report_id)
    (session[:rpid] ||= {})[current_mission.shortcode] = report_id
  end

  # Yields to a block and caches the result and stores in an ivar with the given `name`.
  # Computes a cache key based on given dependencies (looked up in `cache_keys`) and on `name`.
  def instance_variable_cache(name, dependencies: %i[responses enumerator_id], **options, &block)
    key = dependencies.map { |d| cache_keys.fetch(d) } << name
    instance_variable_set(name, Rails.cache.fetch(key, **options, &block))
  end

  def cache_keys
    @cache_keys ||= {
      responses: Response.per_mission_cache_key(current_mission),

      # We use assignments instead of users because
      # if a user gets removed or added to the mission, or role changes, that should show up
      # but we don't include users in the cache key since users get updated every request
      # and that would defeat the purpose.
      assignments: Assignment.per_mission_cache_key(current_mission),

      # If the user is an enumerator, include their ID. If they are staffer, coordinator, etc.,
      # return nil. This means all users of other roles will all hit the same cache.
      enumerator_id: current_user.role(current_mission) == "enumerator" ? current_user.id : nil
    }
  end
end
