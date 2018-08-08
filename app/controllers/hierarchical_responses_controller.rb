class HierarchicalResponsesController < ApplicationController
  include CsvRenderable, ResponseIndexable, OdkHeaderable

  # need to load with associations for show and edit
  before_action :load_with_associations, only: [:show, :edit]

  before_action :fix_nil_time_values, only: [:update, :create]

  # authorization via CanCan
  load_and_authorize_resource find_by: :shortcode, class: 'Response', param_method: :response_params
  before_action :alias_response
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
          rescue Search::ParseError
            flash.now[:error] = $!.to_s
            @search_error = true
          end
        end

        decorate_responses

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
          rescue Search::ParseError
            flash.now[:error] = $!.to_s
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
    Results::BlankResponseTreeBuilder.new(@response).build
    # render the form template
    prepare_and_render_form
  end

  def edit
    if @response.checked_out_by_others?(current_user)
      flash.now[:notice] = "#{t('response.checked_out')} #{@response.checked_out_by_name}"
    end
    prepare_and_render_form
  end

  def create
    if request.format == Mime[:xml]
      handle_odk_submission
    else
      web_create_or_update
    end
  end

  def update
    @response.assign_attributes(response_params)
    web_create_or_update
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
      rescue Search::ParseError => e
        flash.now[:error] = e.to_s
        @search_error = true
      end
    end

    @possible_submitters = @possible_submitters.paginate(page: params[:page], per_page: 20)

    render json: {
      possible_submitters: ActiveModel::ArraySerializer.new(@possible_submitters),
      more: @possible_submitters.next_page.present?
    }, select2: true
  end

  def possible_users
    search_mode = params[:search_mode] || "submitters"

    case search_mode
    when "submitters"
      @possible_users = User.assigned_to_or_submitter(current_mission, @response).by_name
    when "reviewers"
      @possible_users = User.with_roles(current_mission, %w[coordinator staffer reviewer]).by_name
    end

    # do search if applicable
    if params[:search].present?
      begin
        @possible_users = User.do_search(@possible_users, params[:search], mission: current_mission)
      rescue Search::ParseError => e
        flash.now[:error] = e.to_s
        @search_error = true
      end
    end

    @possible_users = @possible_users.paginate(page: params[:page], per_page: 20)

    render json: {
      possible_users: ActiveModel::ArraySerializer.new(@possible_users),
      more: @possible_users.next_page.present?
    }, select2: true
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

  def handle_odk_submission
    return render_xml_submission_failure("No XML file attached.", 422) unless params[:xml_submission_file]

    # Store main XML file for debugging purposes.
    UploadSaver.new.save_file(params[:xml_submission_file])

    begin
      @response.user_id = current_user.id
      @response = odk_response_parser.populate_response
      authorize!(:submit_to, @response.form)
      @response.save(validate: false)
      render(body: nil, status: :created)
    rescue CanCan::AccessDenied => e
      render_xml_submission_failure(e, 403)
    rescue ActiveRecord::RecordNotFound => e
      render_xml_submission_failure(e, 404)
    rescue FormVersionError => e
      # 426 - upgrade needed
      # We use this because ODK can't display custom failure messages so this provides a little more info.
      render_xml_submission_failure(e, 426)
    rescue SubmissionError => e
      render_xml_submission_failure(e, 422)
    end
  end

  def odk_response_parser
    Odk::ResponseParser.new(
      response: @response,
      files: open_file_params,
      awaiting_media: odk_awaiting_media?
    )
  end

  # Returns a hash of param keys to open tempfiles for uploaded file parameters.
  def open_file_params
    file_params = params.select { |_k, v| v.is_a?(ActionDispatch::Http::UploadedFile) }.to_unsafe_h
    file_params.map { |k, v| [k, v.tempfile.open] }.to_h.with_indifferent_access
  end

  # Returns whether the ODK submission request params indicate that not all attachments are included.
  def odk_awaiting_media?
    params["*isIncomplete*"] == "yes"
  end

  # prepares objects for and renders the form template
  def prepare_and_render_form
    # Prepare the OldAnswerNodes.
    @nodes = AnswerArranger.new(
      @response,
      placeholders: params[:action] == "show" ? :except_repeats : :all,
      # Must preserve submitted answers when in create/update action.
      dont_load_answers: %w[create update].include?(params[:action])
    ).build.nodes

    @context = Results::ResponseFormContext.new(
      read_only: action_name == "show" || cannot?(:modify_answers, @response)
    )

    # The blank response is used for rendering placeholders for repeat groups
    @blank_response = Response.new(form: @response.form)
    Results::BlankResponseTreeBuilder.new(@blank_response).build

    render(:form)
  end

  def render_xml_submission_failure(exception, code)
    Rails.logger.info("XML submission failed: '#{exception}'")
    render(body: nil, status: code)
  end

  def alias_response
    # CanCanCan loads resource into @hierarchical_response
    @response = @hierarchical_response
  end

  # get the form specified in the params and error if it's not there
  def assign_form
    @response.form = Form.find(params[:form_id])
    check_form_exists_in_mission
  rescue ActiveRecord::RecordNotFound
    return redirect_to(index_url_with_context)
  end

  def response_params
    if params[:response]
      to_permit = [:form_id, :user_id, :incomplete]

      if @response.present? && can?(:review, @response)
        to_permit << [:reviewed, :reviewer_notes, :reviewer_id]
      end

      # In some rare cases, create or update can occur without answers_attributes. Not sure how.
      # Also need to respect the modify_answers permission here.
      if (ans_attribs = params[:response][:answers_attributes]) &&
          (action_name != "update" || can?(:modify_answers, @response))

        # We need to permit each possible answer attribute key for each given hash key in answers_attributes.
        # See https://stackoverflow.com/a/36779535/2066866.
        to_permit << {
          answers_attributes: ans_attribs.keys.map { |k| [k, permitted_answer_attributes] }.to_h
        }
      end

      params.require(:response).permit(to_permit)
    end
  end

  # Returns the permitted keys for an answer and its choices.
  def permitted_answer_attributes
    @permitted_answer_attributes ||= %w(
      id value option_id option_node_id questioning_id relevant rank
      time_value(1i) time_value(2i) time_value(3i) time_value(4i) time_value(5i) time_value(6i)
      datetime_value
      datetime_value(1i) datetime_value(2i) datetime_value(3i)
      datetime_value(4i) datetime_value(5i) datetime_value(6i)
      date_value(1i) date_value(2i) date_value(3i) inst_num media_object_id _destroy
      date_value
    ) << {choices_attributes: %i[id option_id option_node_id checked]}
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
          %w(1 2 3).each { |i| params[:response][:answers_attributes][key]["time_value(#{i}i)"] = "" }
        end
      end
    end
  end
end
