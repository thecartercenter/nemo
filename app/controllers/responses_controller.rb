# frozen_string_literal: true

class ResponsesController < ApplicationController
  include BatchProcessable
  include OdkHeaderable
  include ResponseIndexable
  include CsvRenderable

  # need to load with associations for show and edit
  before_action :load_with_associations, only: %i[show edit]

  before_action :fix_nil_time_values, only: %i[update create]

  # authorization via CanCan
  load_and_authorize_resource find_by: :shortcode
  before_action :assign_form, only: [:new]

  before_action :mark_response_as_checked_out, only: [:edit]

  def index
    @responses = Response.accessible_by(current_ability)

    # handle different formats
    respond_to do |format|
      # html is the normal index page
      format.html do
        # apply search and pagination
        params[:page] ||= 1

        @responses = @responses.with_basic_assoc.order(created_at: :desc)

        # Needed for permission check
        @responses = @responses.includes(user: :assignments)

        @responses = @responses.paginate(page: params[:page], per_page: 20)

        # do search, including excerpts, if applicable
        if params[:search].present?
          begin
            @responses = Response.do_search(@responses, params[:search], {mission: current_mission},
              include_excerpts: true)
          rescue Search::ParseError => error
            flash.now[:error] = error.to_s
            @search_error = true
          end
        end

        decorate_responses

        @selected_ids = params[:sel]

        # render just the table if this is an ajax request
        render(partial: "table_only", locals: {responses: @responses}) if request.xhr?
      end

      # csv output is for exporting responses
      format.csv do
        authorize!(:export, Response)
        @responses = @responses.accessible_by(current_ability, :export)

        # do search, excluding excerpts
        if params[:search].present?
          begin
            @responses = Response.do_search(@responses, params[:search], {mission: current_mission},
              include_excerpts: false)
          rescue Search::ParseError => error
            flash.now[:error] = error.to_s
            return
          end
        end

        # Get the response, for export, but not paginated.
        # We deliberately don't eager load as that is handled in the Results::Csv::Generator class.
        @responses = @responses.order(:created_at)

        @csv = Results::Csv::Generator.new(@responses)
        render_csv("elmo-#{current_mission.compact_name}-responses-#{Time.zone.now.to_s(:filename_datetime)}")
      end
    end
  end

  def show
    # if there is a search param, we try to load the response via the do_search mechanism
    # so that we get highlighted excerpts
    if params[:search]
      # we pass a relation matching only one respoonse, so there should be at most one match
      matches = Response.do_search(Response.where(id: @response.id), params[:search],
        {mission: current_mission}, include_excerpts: true, dont_truncate_excerpts: true)

      # if we get a match, then we use that object instead, since it contains excerpts
      @response = matches.first if matches.first
    end

    prepare_and_render_form
  end

  def new
    setup_condition_computer
    # render the form template
    prepare_and_render_form
  end

  def edit
    flash.now[:notice] = "#{t('response.checked_out')} #{@response.checked_out_by_name}" if @response.checked_out_by_others?(current_user)
    prepare_and_render_form
  end

  def create
    # if this is a non-web submission
    if request.format == Mime::XML
      begin
        @response.user_id = current_user.id
        # If it looks like a J2ME submission, process accordingly
        if params[:data] && params[:data][:'xmlns:jrm'] == "http://dev.commcarehq.org/jr/xforms"
          @submission = XMLSubmission.new response: @response, data: params[:data], source: "j2me"
        else # Otherwise treat it like an ODK submission
          upfile = params[:xml_submission_file]

          # Store file for debugging purposes.
          UploadSaver.new.save_file(params[:xml_submission_file])

          files = params.select { |k, v| v.is_a? ActionDispatch::Http::UploadedFile }
          files.each { |k, v| files[k] = v.tempfile }

          unless upfile
            render_xml_submission_failure("No XML file attached.", 422)
            return false
          end

          @response.awaiting_media = true if params["*isIncomplete*"] == "yes"
          @submission = XMLSubmission.new response: @response, files: files, source: "odk"
        end

        # ensure response's user can submit to the form
        authorize!(:submit_to, @submission.response.form)

        @submission.save

        render(nothing: true, status: 201)
      rescue CanCan::AccessDenied
        render_xml_submission_failure($!, 403)
      rescue ActiveRecord::RecordNotFound
        render_xml_submission_failure($!, 404)
      rescue FormVersionError
        # 426 - upgrade needed
        # We use this because ODK can't display custom failure messages so this provides a little more info.
        render_xml_submission_failure($!, 426)
      rescue SubmissionError
        render_xml_submission_failure($!, 422)
      end
    # for HTML format just use the method below
    else
      web_create_or_update
    end
  end

  def update
    @response.assign_attributes(response_params)
    web_create_or_update
  end

  def bulk_destroy
    scope = Response.accessible_by(current_ability)
    scope = if params[:select_all] == "1"
              scope.where(mission: current_mission)
            else
              scope.where(id: params[:selected].keys)
            end
    ids = scope.pluck(:id)
    Results::ResponseDeleter.instance.delete(ids)
    flash[:success] = t("response.bulk_destroy_deleted", count: ids.size)
    redirect_to(responses_path)
  end

  def destroy
    destroy_and_handle_errors(@response)
    redirect_to(index_url_with_context)
  end

  def possible_submitters
    # get the users to which this response can be assigned
    # which is the users in this mission plus the submitter of this response
    @possible_submitters = User.assigned_to_or_submitter(current_mission, @response).by_name

    # do search if applicable
    if params[:search].present?
      begin
        @possible_submitters = User.do_search(@possible_submitters, params[:search], mission: current_mission)
      rescue Search::ParseError
        flash.now[:error] = $!.to_s
        @search_error = true
      end
    end

    @possible_submitters = @possible_submitters.paginate(page: params[:page], per_page: 20)

    render(json: {
      possible_submitters: ActiveModel::ArraySerializer.new(@possible_submitters),
      more: @possible_submitters.next_page.present?
    }, select2: true)
  end

  def possible_users
    search_mode = params[:search_mode] || "submitters"

    case search_mode
    when "submitters"
      @possible_users = User.assigned_to_or_submitter(current_mission, @response).by_name
    when "reviewers"
      @possible_users = User.with_roles(current_mission, %w(coordinator staffer reviewer)).by_name
    end

    # do search if applicable
    if params[:search].present?
      begin
        @possible_users = User.do_search(@possible_users, params[:search], mission: current_mission)
      rescue Search::ParseError
        flash.now[:error] = $!.to_s
        @search_error = true
      end
    end

    @possible_users = @possible_users.paginate(page: params[:page], per_page: 20)

    render(json: {
      possible_users: ActiveModel::ArraySerializer.new(@possible_users),
      more: @possible_users.next_page.present?
    }, select2: true)
  end

  private

  def setup_condition_computer
    @condition_computer = Forms::ConditionComputer.new(@response.form)
  end

  # loads the response with its associations
  def load_with_associations
    @response = Response.with_associations.friendly.find(params[:id])
  end

  # when editing a response, set timestamp to show it is being worked on
  def mark_response_as_checked_out
    @response.check_out!(current_user)
  end

  # handles creating/updating for the web form
  def web_create_or_update
    check_form_exists_in_mission

    # set source/modifier to web
    @response.source = "web" if params[:action] == "create"
    @response.modifier = "web"

    # check for "update and mark as reviewed"
    @response.reviewed = true if params[:commit_and_mark_reviewed]
    @response.check_in if params[:action] == "update"

    # try to save
    begin
      @response.save!
      set_success_and_redirect(@response)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = I18n.t("activerecord.errors.models.response.general")
      prepare_and_render_form
    end
  end

  # prepares objects for and renders the form template
  def prepare_and_render_form
    # Prepare the OldAnswerNodes.
    set_read_only
    @nodes = AnswerArranger.new(@response,
      placeholders: params[:action] == "show" ? :except_repeats : :all,
      # Must preserve submitted answers when in create/update action.
      dont_load_answers: %w(create update).include?(params[:action])
    ).build.nodes
    render(:form)
  end

  def render_xml_submission_failure(exception, code)
    Rails.logger.info("XML submission failed: '#{exception.to_s}'")
    render(nothing: true, status: code)
  end

  # get the form specified in the params and error if it's not there
  def assign_form
    @response.form = Form.find(params[:form_id])
    check_form_exists_in_mission
  rescue ActiveRecord::RecordNotFound
    redirect_to(index_url_with_context)
  end

  def set_read_only
    @read_only = case action_name
                 when "show"
                   true
                 else
                   cannot?(:modify_answers, @response)
                 end
  end

  def response_params
    if params[:response]
      reviewer_only = if @response.present? && can?(:review, @response)
        [:reviewed, :reviewer_notes, :reviewer_id]
      else
        []
      end

      params.require(:response).permit(:form_id, :user_id, :incomplete, *reviewer_only).tap do |permitted|
        # In some rare cases, create or update can occur without answers_attributes. Not sure how.
        # Also need to respect the modify_answers permission here.
        if params[:response][:answers_attributes] &&
          (action_name != "update" || can?(:modify_answers, @response))
          permit_answer_attributes(permitted)
        end
      end
    end
  end

  def permit_answer_attributes(permitted)
    permitted[:answers_attributes] = {}

    # The answers_attributes hash might look like {'2746' => { ... }, '2731' => { ... }, ... }
    # The keys are irrelevant so we permit all of them, but we only want to permit certain attribs
    # on the answers.
    permitted_answer_attribs = %w(id value option_id option_node_id questioning_id relevant rank
      time_value(1i) time_value(2i) time_value(3i) time_value(4i) time_value(5i) time_value(6i)
      datetime_value
      datetime_value(1i) datetime_value(2i) datetime_value(3i)
      datetime_value(4i) datetime_value(5i) datetime_value(6i)
      date_value(1i) date_value(2i) date_value(3i) inst_num media_object_id _destroy
      date_value)

    params[:response][:answers_attributes].each do |idx, attribs|
      permitted[:answers_attributes][idx] = attribs.permit(*permitted_answer_attribs)
      # Handle choices, which are nested under answers.
      if attribs[:choices_attributes]
        permitted[:answers_attributes][idx][:choices_attributes] = {}
        attribs[:choices_attributes].each do |idx2, attribs2|
          permitted[:answers_attributes][idx][:choices_attributes][idx2] = attribs2.permit(
            :id, :option_id, :option_node_id, :checked)
        end
      end
    end
  end

  def check_form_exists_in_mission
    if @response.form.mission_id != current_mission.id
      @error = CanCan::AccessDenied.new("Form does not exist in this mission.", :create, :response)
      raise @error
    end
  end

  # Rails seems to have a bug wherein if a time_select field is left blank,
  # the value that gets stored is not nil, but 00:00:00.
  # This seems to be because the date is passed in as 0001-01-01 so it doesn't look like a nil.
  # So here we correct it by setting the incoming parameters in such a situation to all blanks.
  def fix_nil_time_values
    if params[:response] && params[:response][:answers_attributes]
      params[:response][:answers_attributes].each do |key, attribs|
        if attribs["time_value(4i)"].blank? && attribs["time_value(5i)"].blank?
          %w[1 2 3].each { |i| params[:response][:answers_attributes][key]["time_value(#{i}i)"] = "" }
        end
      end
    end
  end
end
