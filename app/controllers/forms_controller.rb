# frozen_string_literal: true

# FormController
class FormsController < ApplicationController
  # Increment to expire caches for this controller as needed due to changes.
  CACHE_SUFFIX = "3"

  include StandardImportable
  include BatchProcessable
  include ODKHeaderable
  include ERB::Util

  # special find method before load_resource
  before_action :load_form, only: %i[show edit update]

  # authorization via cancan
  load_and_authorize_resource

  # We manually authorize these against :download.
  skip_authorize_resource only: %i[odk_manifest odk_itemsets]

  # in the choose_questions action we have a question form so we need this Concern
  include QuestionFormable

  decorates_assigned :forms, :form
  helper_method :questions

  def index
    respond_to do |format|
      format.html do
        if params[:dropdown]
          @forms = @forms.live.by_name
          render(partial: "dropdown")
        else
          @forms = @forms.with_responses_counts.by_status.by_name
          load_importable_objs
          render(:index)
        end
      end

      # OpenRosa format for ODK
      format.xml do
        authorize!(:download, Form)
        # Also cache based on host because this endpoint returns full URLs for form access.
        # Ignoring host leads to issues with proxies or when debugging across localhost/0.0.0.0/ngrok.
        @cache_key = "#{Form.odk_index_cache_key(mission: current_mission)}/#{request.host}/#{CACHE_SUFFIX}"

        # We have to skip forms that have not yet been rendered since we won't have access to their
        # checksum hash. It should be rare that a live form is not also rendered.
        @forms = @forms.live.rendered
      end
    end
  end

  def show
    setup_condition_computer
    respond_to do |format|
      format.html do
        if params[:print] && request.xhr?
          render(partial: "printable")
        else
          prepare_and_render_form
        end
      end
      format.xml do
        authorize!(:download, @form)
        @form.add_download
        @form.odk_xml.download { |chunk| response.stream.write(chunk) }
      ensure
        response.stream.close
      end
    end
  end

  def new
    setup_condition_computer
    prepare_and_render_form
  end

  def edit
    setup_condition_computer
    prepare_and_render_form
  end

  def sms_guide
    return (flash.now[:error] = I18n.t("forms.sms_guide.draft_error", form_name: @form.name)) if @form.draft?

    # Current locale (string)
    @locale = params[:lang] || I18n.locale.to_s

    # Options for the dropdown (symbols).
    # Union of system locales plus locales in the mission config (which may be different than system locales).
    @locales = I18n.available_locales | current_mission_config.preferred_locales

    @qings_with_indices = @form.smsable_questionings

    # If there are more than one incoming numbers, we need to set a flash notice.
    @incoming_sms_numbers = current_mission_config.incoming_sms_numbers
    @number_appendix = @incoming_sms_numbers.size > 1
  end

  # Format is always :xml
  def odk_manifest
    authorize!(:download, @form)
    @cache_key = "#{@form.odk_download_cache_key}/manifest/#{CACHE_SUFFIX}"
    return if fragment_exist?(@cache_key)

    questions = @form.enabled_questionings.map(&:question).select(&:media_prompt?)
    @decorated_questions = ODK::QuestionDecorator.decorate_collection(questions)
    @itemsets_attachment = ODK::ItemsetsFormAttachment.new(form: @form).ensure_generated
  end

  # Format is always :csv
  def odk_itemsets
    authorize!(:download, @form)
  end

  def create
    if @form.save
      set_success_and_redirect(@form, to: edit_form_path(@form))
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.form.general")
      prepare_and_render_form
    end
  end

  def update
    Form.transaction do
      @form.assign_attributes(form_params)
      authorize!(:rename, @form) if @form.name_changed?
      @form.save!

      if params[:save_and_go_live].present?
        @form.update_status(:live) # Will automatically call FormRenderJob.
        set_success_and_redirect(@form, to: forms_path)
      else
        ODK::FormRenderJob.perform_later(@form) if @form.live?
        set_success_and_redirect(@form, to: edit_form_path(@form))
      end
    end
  # handle other validation errors
  rescue ActiveRecord::RecordInvalid
    prepare_and_render_form
  end

  def destroy
    destroy_and_handle_errors(@form)
    redirect_to(index_url_with_context)
  end

  def re_cache
    Rails.logger.debug { "OData dirty_json cause: manual re-cache of #{@form.id}" }
    Response.where(form_id: @form.id).update_all(dirty_json: true)
    flash[:success] = t("operation.details.cache_odata")
    redirect_after_status_change
  end

  def go_live
    @form.update_status(:live)
    redirect_after_status_change
  end

  def pause
    @form.update_status(:paused)
    redirect_after_status_change
  end

  def return_to_draft
    @form.update_status(:draft)
    redirect_after_status_change
  end

  def increment_version
    @form.increment_version
    ODK::FormRenderJob.perform_later(@form) if @form.live?
    render(json: {
      value: @form.current_version.decorate.name,
      minimum_version_options: @form.decorate.minimum_version_options
    })
  end

  # shows the form to either choose existing questions or create a new one to add
  def choose_questions
    authorize!(:add_questions, @form)

    # get questions for choice list
    @questions = Question.includes(:tags).by_code.accessible_by(current_ability).not_in_form(@form)

    # setup new questioning for use with the questioning form
    init_qing(form_id: @form.id, ancestry: @form.root_id, question_attributes: {})
    setup_qing_form_support_objs
  end

  # adds questions selected in the big list to the form
  def add_questions
    # load the question objects
    questions = restrict_scope_to_selected_objects(Question.accessible_by(current_ability))

    # raise error if no valid questions (this should be impossible)
    raise "no valid questions given" if questions.empty?

    # add questions to form and try to save
    @form.add_questions_to_top_level(questions)
    if @form.save
      flash[:success] = t("form.questions_add_success")
    else
      flash[:error] = t("form.questions_add_error", msg: @form.errors.full_messages.join(";"))
    end

    # redirect to form edit
    redirect_to(edit_form_url(@form))
  end

  def clone
    begin
      cloned = @form.replicate(mode: :clone)
      flash[:modified_obj_id] = cloned.id
      flash[:success] = t("form.clone_success", form_name: @form.name)
    rescue StandardError => e
      flash[:error] = t("form.clone_error", msg: e.to_s)
    end
    redirect_to(index_url_with_context)
  end

  # Standard CSV export.
  def export
    Sentry.capture_message("Exporting form: CSV")
    exporter = Forms::Export.new(@form)
    send_data(exporter.to_csv, filename: "form-#{@form.name.dasherize}-#{Time.zone.today}.csv")
  end

  # ODK XML export.
  def export_xml
    Sentry.capture_message("Exporting form: XML")
    send_data(@form.odk_xml.download, filename: "form-#{@form.name.dasherize}-#{Time.zone.today}.xml")
  end

  # XLSForm export.
  def export_xls
    Sentry.capture_message("Exporting form: XLSForm")
    exporter = Forms::Export.new(@form)
    send_data(exporter.to_xls.html_safe, filename: "xlsform-#{@form.name.dasherize}-#{Time.zone.today}.xls") # rubocop:disable Rails/OutputSafety
  end

  # ODK XML export for all published forms.
  # Theoretically works for standard forms too, but they have no XML so can't be exported at this time.
  def export_all
    Sentry.capture_message("Exporting forms: All XML")
    forms = Form.where(mission: current_mission) # Mission could be nil for standard forms.
    forms = forms.published if current_mission.present?
    forms_group = current_mission&.compact_name || "standard"
    zipfile_path = Rails.root.join("tmp/forms-#{forms_group}-#{Time.zone.today}.zip")
    zip_all(zipfile_path, forms)

    # Use send_data (not send_file) in order to block until it's finished before deleting.
    File.open(zipfile_path, "r") { |f| send_data(f.read, filename: File.basename(zipfile_path)) }
    FileUtils.rm(zipfile_path)
  end

  private

  # Decorates questions for choose_questions view.
  def questions
    # Need to specify the plain CollectionDecorator here because otherwise it will use PaginatingDecorator
    # which doesn't work here because we're not paginating.
    @decorated_questions ||= # rubocop:disable Naming/MemoizedInstanceVariableName
      Draper::CollectionDecorator.decorate(@questions, with: QuestionDecorator)
  end

  # Given a set of forms, put them all in a zip file for download.
  def zip_all(zipfile_path, forms)
    Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
      forms.each do |form|
        form_name = "form-#{form.name.dasherize}-#{Time.zone.today}.xml"
        zipfile.get_output_stream(form_name) { |f| f.write(form.odk_xml.download) }
      rescue Zip::EntryExistsError => e
        Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Form: #{form.id}"))
        notify_admins(e)
        next
      end
    end
  end

  def setup_condition_computer
    @condition_computer = Forms::ConditionComputer.new(@form)
  end

  # prepares objects and renders the form template
  def prepare_and_render_form
    # We need this array only when in mission mode since it's for the API permissions which are not
    # shown in admin mode.
    @users = User.assigned_to(current_mission).by_name unless admin_mode?
    render(:form)
  end

  def load_form
    @form = Form.find(params[:id])
  end

  def form_params
    params.require(:form).permit(:name, :smsable, :allow_incomplete, :default_response_name,
      :minimum_version_id, :authenticate_sms, :sms_relay, :access_level, recipient_ids: [])
  end

  def redirect_after_status_change
    redirect_to(
      case params[:source]
      when "show" then form_path(@form)
      when "edit" then edit_form_path(@form)
      else index_url_with_context
      end
    )
  end
end
