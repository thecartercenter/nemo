# frozen_string_literal: true

# FormController
class FormsController < ApplicationController
  # Increment to expire caches for this controller as needed due to changes.
  CACHE_SUFFIX = "2"

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
        @forms = @forms.live
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

      # for xml, render openrosa
      format.xml do
        authorize!(:download, @form)
        @form.add_download
        @form = ODK::DecoratorFactory.decorate(@form)
        @questionings = ODK::DecoratorFactory.decorate_collection(@form.questionings)
        @option_sets = ODK::DecoratorFactory.decorate_collection(@form.option_sets)
      end
    end
  end

  def sms_guide
    return (flash.now[:error] = I18n.t("forms.sms_guide.draft_error", form_name: @form.name)) if @form.draft?

    # determine the most appropriate language to show the form in
    # if params[:lang] is set, use that
    # otherwise try to use the current locale set
    @locale = params[:lang] || I18n.locale

    @qings_with_indices = @form.smsable_questionings

    # If there are more than one incoming numbers, we need to set a flash notice.
    @number_appendix = configatron.incoming_sms_numbers.size > 1
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
    set_api_users
    if @form.save
      set_success_and_redirect(@form, to: edit_form_path(@form))
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.form.general")
      prepare_and_render_form
    end
  end

  def update
    Form.transaction do
      set_api_users
      @form.assign_attributes(form_params)
      authorize!(:rename, @form) if @form.name_changed?
      @form.save!
      if params[:save_and_go_live].present?
        @form.update_status(:live)
        set_success_and_redirect(@form, to: forms_path)
      else
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

  private

  # Decorates questions for choose_questions view.
  def questions
    # Need to specify the plain CollectionDecorator here because otherwise it will use PaginatingDecorator
    # which doesn't work here because we're not paginating.
    @decorated_questions ||= # rubocop:disable Naming/MemoizedInstanceVariableName
      Draper::CollectionDecorator.decorate(@questions, with: QuestionDecorator)
  end

  def setup_condition_computer
    @condition_computer = Forms::ConditionComputer.new(@form)
  end

  def set_api_users
    return unless params[:form][:access_level] == "protected"

    @form.whitelistings.destroy_all if action_name == "update"

    (params[:whitelistings] || []).each do |api_user|
      @form.whitelistings.new(user_id: api_user)
    end
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
