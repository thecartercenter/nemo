# frozen_string_literal: true

class ResponsesController < ApplicationController
  include ActionView::Helpers::NumberHelper

  PER_PAGE = 20
  REFRESH_INTERVAL = 30_000 # ms

  TMP_UPLOADS_PATH = Rails.root.join("tmp/odk_uploads")
  CSV_EXPORT_LIMIT = 100_000
  CSV_EXPORT_WARNING = 5_000

  include BatchProcessable
  include ODKHeaderable
  include ResponseIndexable
  include OperationQueueable
  include Searchable

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
        @responses = @responses.includes(user: :assignments) # Needed for permission check
        @responses = @responses.paginate(page: params[:page], per_page: PER_PAGE)

        # Redirect immediately for exact shortcode searches.
        if params[:search].present? && (resp = Response.find_by(shortcode: params[:search].downcase))
          redirect_to(can?(:update, resp) ? edit_response_path(resp) : response_path(resp))
        end

        # Manually show success message after AJAX request.
        flash.now[:success] = params[:enketo_success] if params[:enketo_success].present?

        searcher = build_searcher(@responses)
        @responses = apply_searcher_safely(searcher)
        @searcher_serializer = ResponsesSearcherSerializer
        @searcher = searcher

        @selected_ids = params[:sel]
        @selected_all_pages = params[:select_all_pages]

        @response_csv_export_options = ResponseCSVExportOptions.new
        @response_odata_export_options = ResponseODataExportOptions.new(
          mission_url: "#{request.base_url}#{current_root_path}"
        )

        # render just the table if this is an ajax request
        render(partial: "table_only", locals: {responses: responses}) if request.xhr?
      end

      # csv output is for exporting responses, media, and odk xml files
      format.csv do
        authorize!(:export, Response)
        enqueue_jobs
        prep_operation_queued_flash(:response_csv_export)
        redirect_to(responses_path)
      end
    end
  end

  def show
    flash_recently_modified_warnings

    save_editor_preference
    return enketo if use_enketo?

    prepare_and_render_form
  end

  def new
    save_editor_preference
    return enketo if use_enketo?

    setup_condition_computer
    Results::BlankResponseTreeBuilder.new(@response).build
    # render the form template
    prepare_and_render_form
  end

  def edit
    if @response.checked_out_by_others?(current_user)
      flash.now[:notice] = "#{t('response.checked_out')} #{@response.checked_out_by_name}"
    end

    flash_recently_modified_warnings

    save_editor_preference
    return enketo if use_enketo?

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

  def enketo_update
    handle_odk_update
  end

  def bulk_destroy
    @responses = restrict_by_search_and_ability_and_selection(@responses)
    result = ResponseDestroyer.new(scope: @responses, ability: current_ability).destroy!
    flash[:success] = t("response.bulk_destroy_deleted", count: result[:destroyed])
    redirect_to(responses_path)
  end

  def destroy
    destroy_and_handle_errors(@response)
    redirect_to(index_url_with_context)
  end

  def possible_submitters
    users = User.assigned_to(current_mission)
    if params[:response_id].present? && (response = Response.find(params[:response_id]))
      users = users.or(User.where(id: response.user_id))
    end
    render_possible_users(users)
  end

  def possible_reviewers
    users = User.with_roles(current_mission, %w[coordinator staffer reviewer])
    render_possible_users(users)
  end

  def media_size
    ability = Ability.new(user: current_user, mission: current_mission)
    selected = params[:selectAll].present? ? [] : params[:selected] # Empty selection is equivalent to "all".
    packager = create_packager(ability, selected)
    render(json: packager.download_meta)
  end

  private

  # Returns true if the user wants to use Enketo instead of NEMO's webform.
  def use_enketo?
    # We check for nil, not blank, because blank means it was intentionally unset and they want to use NEMO.
    params[:enketo].present? || (params[:enketo].nil? && current_user.editor_preference == "enketo")
  end

  def save_editor_preference
    current_user.update!(editor_preference: use_enketo? ? "enketo" : "nemo")
  end

  # Warn the user if they're viewing possibly-stale data.
  def flash_recently_modified_warnings
    if use_enketo? && last_modified_by_nemo?
      flash.now[:alert] = t("response.modified_by_web", date: @response.updated_at)
    elsif !use_enketo? && last_modified_by_enketo?
      flash.now[:alert] = t("response.modified_by_enketo", date: @response.updated_at)
    end
  end

  def last_modified_by_nemo?
    @response.modifier == "web" || (@response.source == "web" && @response.modifier.nil?)
  end

  def last_modified_by_enketo?
    @response.modifier == "enketo" || (@response.source == "enketo" && @response.modifier.nil?)
  end

  def create_packager(ability, selected)
    case params[:download_type]
    when "media"
      packager = Utils::BulkMediaPackager.new(
        ability: ability, search: params[:search], selected: selected, operation: nil
      )
    when "xml"
      packager = Utils::XmlPackager.new(
        ability: ability, search: params[:search], selected: selected, operation: nil
      )
    end
    packager
  end

  def render_possible_users(possible_users)
    possible_users = apply_search(possible_users).by_name
      .paginate(page: params[:page], per_page: 20)

    render(json: {
      possible_users: UserSerializer.render_as_json(possible_users),
      more: possible_users.next_page.present?
    })
  end

  def setup_condition_computer
    @condition_computer = Forms::ConditionComputer.new(@response.form)
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
    @response.modifier = "web" if params[:action] == "update"

    # check for "update and mark as reviewed"
    @response.reviewed = true if params[:commit_and_mark_reviewed]
    @response.check_in if params[:action] == "update"

    if can?(:modify_answers, @response)
      parser = Results::WebResponseParser.new(@response)
      parser.parse(params.require(:response))
    end

    # try to save
    begin
      @response.save!
      set_success_and_redirect(@response)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = I18n.t("activerecord.errors.models.response.general")
      prepare_and_render_form
    end
  end

  # For Collect or Enketo submissions.
  def handle_odk_submission
    submission_file = params[:xml_submission_file]
    raise ActionController::MissingFile unless submission_file

    if ODK::DuplicateChecker.new(open_file_params, current_user).duplicate?
      Sentry.capture_message("Ignored simple duplicate")
      render(body: nil, status: :created) and return
    end

    # Temp copy for diagnostics in case of issues.
    tmp_path = copy_to_tmp_path(submission_file)

    @response.user_id = current_user.id
    @response.device_id = params[:deviceID]
    @response.source = use_enketo? ? "enketo" : "odk"
    @response.odk_xml = submission_file
    @response = odk_response_parser.populate_response
    authorize!(:submit_to, @response.form)
    @response.save!(validate: false)

    enketo_response = use_enketo? ? {redirect: enketo_redirect} : {}
    render_ajax(enketo_response, :created)
    FileUtils.rm(tmp_path)
  # See config/initializers/http_status_code.rb for custom status definitions.
  # ODK can't display custom failure messages so these statuses provide a little more info;
  # the error message is only used for our logging.
  rescue ActionController::MissingFile
    msg = I18n.t("activerecord.errors.models.response.missing_xml")
    render_xml_submission_failure(msg, :unprocessable_entity)
  rescue CanCan::AccessDenied => e
    render_xml_submission_failure(e, :forbidden)
  rescue ActiveRecord::RecordNotFound => e
    render_xml_submission_failure(e, :not_found)
  rescue FormVersionError => e
    render_xml_submission_failure(e, :upgrade_required)
  rescue FormStatusError => e
    render_xml_submission_failure(e, :form_not_live)
  rescue SubmissionError => e
    render_xml_submission_failure(e, :unprocessable_entity)
  rescue ActiveRecord::SerializationFailure => e
    render_xml_submission_failure(e, :service_unavailable)
  end

  # For Enketo edits.
  def handle_odk_update
    check_form_exists_in_mission
    authorize!(:modify_answers, @response)

    submission_file = params[:xml_submission_file]
    raise ActionController::MissingFile unless submission_file

    # Temp copy for diagnostics in case of issues.
    tmp_path = copy_to_tmp_path(submission_file)

    @response.modifier = "enketo"
    @response.modified_odk_xml = submission_file
    @response.save! # Must save first before destroying answers, otherwise attachment gets lost.

    # Get rid of the answer tree starting from the root AnswerGroup, then repopulate it,
    # without overwriting the original odk_xml submission file.
    @response.root_node&.destroy!
    odk_response_parser.populate_response

    @response.save!

    enketo_response = use_enketo? ? {redirect: enketo_redirect} : {}
    render_ajax(enketo_response, :ok)
    FileUtils.rm(tmp_path)
  rescue ActionController::MissingFile
    render_ajax({error: I18n.t("activerecord.errors.models.response.missing_xml")}, :unprocessable_entity)
  rescue CanCan::AccessDenied
    render_ajax({error: I18n.t("permission_error.no_permission_action")}, :forbidden)
  rescue ActiveRecord::RecordInvalid, SubmissionError
    render_ajax({error: I18n.t("activerecord.errors.models.response.general")}, :unprocessable_entity)
  end

  # Copy the uploaded file to a temporary path we control so that if saving the response fails,
  # we can inspect the XML to find out why.
  def copy_to_tmp_path(submission_file)
    upload_path = submission_file.tempfile.path
    upload_name = File.basename(upload_path)
    tmp_path = TMP_UPLOADS_PATH.join(upload_name)
    FileUtils.mkdir_p(TMP_UPLOADS_PATH)
    FileUtils.cp(upload_path, tmp_path)
    tmp_path
  end

  def odk_response_parser
    ODK::ResponseParser.new(
      response: @response,
      files: open_file_params,
      awaiting_media: odk_awaiting_media?
    )
  end

  # Returns a hash of param keys to open tempfiles for uploaded file parameters.
  def open_file_params
    file_params = params.select { |_k, v| v.is_a?(ActionDispatch::Http::UploadedFile) }.to_unsafe_h
    file_params.transform_values { |v| v.tempfile.open }.with_indifferent_access
  end

  # Returns whether the ODK submission request params indicate that not all attachments are included.
  def odk_awaiting_media?
    params["*isIncomplete*"] == "yes"
  end

  # Renders an Enketo form instead of a NEMO form.
  def enketo
    # Fail fast if we're on the wrong node version (this happens most often in development).
    raise "Error: Unexpected Node version #{`node -v`}" unless `node -v`.match?("v16")

    # Enketo can't render anything if we haven't rendered it to XML (e.g. unpublished draft).
    if @response.form.odk_xml.blank?
      flash[:error] = t("activerecord.errors.models.response.no_form_xml")
      return redirect_to(params.permit!.merge("enketo": ""))
    end

    # This check is here until we have a way to encode legacy editor responses as ODK XML.
    if action_name == "edit" && !@response.odk_xml.attached?
      flash[:error] = t("activerecord.errors.models.response.no_response_xml")
      return redirect_to(params.permit!.merge("enketo": ""))
    end

    @enketo_form_obj = enketo_form_obj
    @enketo_instance_str = enketo_instance_str
    @read_only = read_only?

    # Fail fast if something went wrong with the CLI process.
    raise RuntimeError unless @enketo_form_obj.present?

    render(:enketo_form)
  end

  # The blank form template.
  # Returns a string that's safe to print in a JS script.
  def enketo_form_obj
    # Terrapin seems to return an ASCII-encoded string, so we must interpret it
    # as UTF-8 in order for the rest of the page to work for some kinds of forms.
    command = Terrapin::CommandLine.new("node", ":transformer :xml")
    command.run(
      transformer: Rails.root.join("lib/enketo-transformer-service/index.js"),
      xml: @response.form.odk_xml.download
    ).force_encoding("utf-8").chomp.html_safe # rubocop:disable Rails/OutputSafety
  end

  # The submission for a given form.
  # Returns a string that's safe to print in a JS script.
  def enketo_instance_str
    # Determine the most recently modified attachment.
    xml = @response.modified_odk_xml.presence || @response.odk_xml
    xml.download.to_json.html_safe # rubocop:disable Rails/OutputSafety
  end

  # Generates a redirect path that can be returned to JS via AJAX.
  def enketo_redirect
    index_url_with_context(enketo_success: success_msg(@response))
  end

  # prepares objects for and renders the form template
  def prepare_and_render_form
    @context = Results::ResponseFormContext.new(read_only: read_only?)

    # The blank response is used for rendering placeholders for repeat groups
    @blank_response = Response.new(form: @response.form)
    Results::BlankResponseTreeBuilder.new(@blank_response).build

    render(:form)
  end

  def read_only?
    action_name == "show" || cannot?(:modify_answers, @response)
  end

  def render_xml_submission_failure(exception, code)
    Rails.logger.info("XML submission failed: '#{exception}'")
    # TODO: Render json here too so enketo can display it?
    render(body: nil, status: code)
  end

  def render_ajax(json, code)
    render(json: json, status: code, content_type: :json)
  end

  def alias_response
    # CanCanCan loads resource into @_response
    @response = @_response
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
      to_permit = %i[form_id user_id incomplete]

      to_permit << %i[reviewed reviewer_notes reviewer_id] if @response.present? && can?(:review, @response)

      params.require(:response).permit(to_permit)
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

  def enqueue_jobs
    download_types = {
      download_csv: ResponseCSVExportOperationJob,
      download_media: BulkMediaDownloadOperationJob,
      download_xml: XmlDownloadOperationJob
    }
    download_types.each do |dt, job|
      download_param = params[:response_csv_export_options][dt]
      enqueue(job, dt) if download_param.present? && download_param == "1"
    end
  end

  def enqueue(klass, msg)
    operation = Operation.new(
      creator: current_user,
      mission: current_mission,
      job_class: klass,
      details: t("operation.details.#{msg}"),
      job_params: {search: params[:search], options: extract_export_options}
    )
    operation.enqueue
  end

  def extract_export_options
    select_all = params[:select_all_pages].present?
    selected = params[:selected] || {}
    {
      long_text_behavior: params[:response_csv_export_options][:long_text_behavior],
      download_media: params[:response_csv_export_options][:download_media],
      download_xml: params[:response_csv_export_options][:download_xml],
      selected: select_all ? [] : selected.keys # Empty selection is equivalent to "all".
    }
  end
end
