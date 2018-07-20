# frozen_string_literal: true

# FormController
class FormsController < ApplicationController
  include StandardImportable
  include BatchProcessable
  include OdkHeaderable
  include ERB::Util
  helper OdkHelper

  # special find method before load_resource
  before_action :load_form, :only => [:show, :edit, :update]

  after_action :check_rank_fail

  # authorization via cancan
  load_and_authorize_resource

  # We manually authorize these against :download.
  skip_authorize_resource only: %i[odk_manifest odk_itemsets]

  # in the choose_questions action we have a question form so we need this Concern
  include QuestionFormable

  def index
    # handle different formats
    respond_to do |format|
      # render normally if html
      format.html do
        # if requesting the dropdown menu
        if params[:dropdown]
          @forms = @forms.published.default_order
          render(partial: "dropdown")

        # otherwise, it's a normal request
        else
          # add some eager loading stuff, and ordering
          @forms = @forms.default_order
          load_importable_objs
          render(:index)
        end
      end

      # get only published forms and render openrosa if xml requested
      format.xml do
        authorize!(:download, Form)
        @cache_key = Form.odk_index_cache_key(mission: current_mission)
        unless fragment_exist?(@cache_key)
          # This query is not deferred so we have to check if it should be run or not.
          @forms = @forms.published
        end
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
      # for html, render the printable style if requested, otherwise render the form
      format.html do
        if params[:print] && request.xhr?
          render(:form, layout: false)
        # otherwise just normal!
        else
          prepare_and_render_form
        end
      end

      # for xml, render openrosa
      format.xml do
        authorize!(:download, @form)
        @form.add_download

        # xml style defaults to odk but can be specified via query string
        @style = params[:style] || "odk"
        @form = Odk::DecoratorFactory.decorate(@form)
      end
    end
  end

  def sms_guide
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
    @cache_key = "#{@form.odk_download_cache_key}/manifest"
    unless fragment_exist?(@cache_key)
      questions = @form.visible_questionings.map(&:question).select(&:audio_prompt_file_name)
      @decorated_questions = Odk::QuestionDecorator.decorate_collection(questions)
      @ifa = ItemsetsFormAttachment.new(form: @form)
      @ifa.ensure_generated
    end
  end

  # Format is always :csv
  def odk_itemsets
    authorize!(:download, @form)
  end

  def create
    set_api_users
    @form.is_standard = true if current_mode == "admin"

    if @form.save
      @form.create_root_group!(mission: @form.mission, form: @form)
      @form.save!
      set_success_and_redirect(@form, to: edit_form_path(@form))
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.form.general")
      prepare_and_render_form
    end
  end

  def update
    begin
      Form.transaction do
        set_api_users
        # save basic attribs
        @form.assign_attributes(form_params)

        # check special permissions
        authorize!(:rename, @form) if @form.name_changed?

        # save everything
        @form.save!

        # publish if requested
        if params[:save_and_publish].present?
          @form.publish!
          set_success_and_redirect(@form, to: forms_path)
        else
          set_success_and_redirect(@form, to: edit_form_path(@form))
        end
      end
    # handle other validation errors
    rescue ActiveRecord::RecordInvalid
      prepare_and_render_form
    end
  end

  def destroy
    destroy_and_handle_errors(@form)
    redirect_to(index_url_with_context)
  end

  # publishes/unpublishes a form
  def publish
    verb = @form.published? ? :unpublish : :publish
    begin
      @form.send("#{verb}!")
      flash[:success] = t("form.#{verb}_success")
    rescue StandardError => e
      flash[:error] = t("form.#{verb}_error", msg: e.to_s)
    end

    # redirect to index or edit
    redirect_to(verb == :publish ? index_url_with_context : edit_form_path(@form))
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
    questions = load_selected_objects(Question)

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

  # removes selected questions from the form
  def remove_questions
    # get the selected questionings
    qings = load_selected_objects(Questioning)
    # destroy
    begin
      @form.destroy_questionings(qings)
      flash[:success] = t("form.questions_remove_success")
    rescue StandardError => e
      flash[:error] = t("form.#{e}")
    end
    # redirect to form edit
    redirect_to(edit_form_url(@form))
  end

  # makes an unpublished copy of the form that can be edited without affecting the original
  def clone
    begin
      cloned = @form.replicate(mode: :clone)

      # save the cloned obj id so that it will flash
      flash[:modified_obj_id] = cloned.id

      flash[:success] = t("form.clone_success", form_name: @form.name)
    rescue StandardError => e
      flash[:error] = t("form.clone_error", msg: e.to_s)
    end
    redirect_to(index_url_with_context)
  end

  private

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
    if admin_mode?
      @form.is_standard = true
    else
      # We need this array only when in mission mode since it's for the API permissions which are not
      # shown in admin mode.
      @users = User.assigned_to(current_mission).by_name
    end
    render(:form)
  end

  def load_form
    @form = Form.find(params[:id])
  end

  def form_params
    params.require(:form).permit(:name, :smsable, :allow_incomplete, :default_response_name,
      :authenticate_sms, :sms_relay, :access_level, recipient_ids: [])
  end
end
