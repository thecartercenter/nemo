class FormsController < ApplicationController
  include StandardImportable
  include BatchProcessable
  helper OdkHelper

  # special find method before load_resource
  before_filter :load_form, :only => [:show, :edit, :update]

  # authorization via cancan
  load_and_authorize_resource

  # We manually authorize these against :download.
  skip_authorize_resource only: [:odk_manifest, :odk_itemsets]

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
          render(:partial => "dropdown")

        # otherwise, it's a normal request
        else
          # add some eager loading stuff, and ordering
          @forms = @forms.with_questioning_and_copy_counts.default_order
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
        render_openrosa
      end
    end
  end

  def new
    prepare_and_render_form
  end

  def edit
    prepare_and_render_form
  end

  def show
    respond_to do |format|

      # for html, render the printable or sms_guide styles if requested, otherwise render the form
      format.html do
        if params[:print] && request.xhr?
          render(:form, :layout => false)

        # sms guide style
        elsif params[:sms_guide]
          # determine the most appropriate language to show the form in
          # if params[:lang] is set, use that
          @lang = if params[:lang]
            params[:lang]
          # otherwise try to use the user's lang pref or the default
          else
            current_user.pref_lang.to_sym || I18n.default_locale
          end
          render("sms_guide")

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
        @style = params[:style] || 'odk'

        render_openrosa
      end
    end
  end

  # Format is always :xml
  def odk_manifest
    authorize!(:download, @form)
    @cache_key = @form.odk_download_cache_key
    unless fragment_exist?(@cache_key)
      @ifa = ItemsetsFormAttachment.new(form: @form)
      @ifa.ensure_generated
    end
    render_openrosa
  end

  # Format is always :csv
  def odk_itemsets
    authorize!(:download, @form)

  end

  def create
    @form.is_standard = true if current_mode == 'admin'
    if @form.save
      @form.create_root_group!(mission: @form.mission, form: @form, rank: 1)
      @form.save!
      set_success_and_redirect(@form, :to => edit_form_path(@form))
    else
      flash.now[:error] = I18n.t('activerecord.errors.models.form.general')
      prepare_and_render_form
    end
  end

  def update
    begin
      Form.transaction do
        update_api_users
        # save basic attribs
        @form.assign_attributes(params[:form])

        # check special permissions
        authorize!(:rename, @form) if @form.name_changed?

        # update ranks if provided (possibly raising condition ordering error)
        # We convert IDs and ranks to integer before passing.
        @form.update_ranks(Hash[*params[:rank].to_a.flatten.map(&:to_i)]) if params[:rank] && can?(:reorder_questions, @form)

        # save everything
        @form.save!

        # publish if requested
        if params[:save_and_publish].present?
          @form.publish!
          set_success_and_redirect(@form, :to => forms_path)
        else
          set_success_and_redirect(@form, :to => edit_form_path(@form))
        end
      end
    # handle problem with conditions
    rescue ConditionOrderingError
      flash.now[:error] = I18n.t('activerecord.errors.models.form.ranks_break_conditions')
      prepare_and_render_form

    # handle other validation errors
    rescue ActiveRecord::RecordInvalid
      prepare_and_render_form
    end
  end

  def destroy
    destroy_and_handle_errors(@form)
    redirect_to(index_url_with_page_num)
  end

  # publishes/unpublishes a form
  def publish
    verb = @form.published? ? :unpublish : :publish
    begin
      @form.send("#{verb}!")
      flash[:success] = t("form.#{verb}_success")
    rescue
      flash[:error] = t("form.#{verb}_error", :msg => $!.to_s)
    end

    # redirect to index or edit
    redirect_to(verb == :publish ? index_url_with_page_num : edit_form_path(@form))
  end

  # shows the form to either choose existing questions or create a new one to add
  def choose_questions
    authorize!(:add_questions, @form)

    # get questions for choice list
    @questions = Question.includes(:tags).with_assoc_counts.by_code.accessible_by(current_ability).not_in_form(@form)

    # setup new questioning for use with the questioning form
    init_qing(:form_id => @form.id, :ancestry => @form.root_id, :question_attributes => {})
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
      flash[:error] = t("form.questions_add_error", :msg => @form.errors.full_messages.join(';'))
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
    rescue
      flash[:error] = t("form.#{$!}")
    end
    # redirect to form edit
    redirect_to(edit_form_url(@form))
  end

  # makes an unpublished copy of the form that can be edited without affecting the original
  def clone
    begin
      cloned = @form.replicate(:mode => :clone)

      # save the cloned obj id so that it will flash
      flash[:modified_obj_id] = cloned.id

      flash[:success] = t("form.clone_success", :form_name => @form.name)
    rescue
      flash[:error] = t("form.clone_error", :msg => $!.to_s)
    end
    redirect_to(index_url_with_page_num)
  end

  private

    def update_api_users
      return unless params[:form][:access_level] == 'protected'
      @form.whitelist_users.destroy
      (params[:whitelist_users] || []).each do |api_user|
        @form.whitelist_users.create(user_id: api_user)
      end
    end

    # adds the appropriate headers for openrosa content
    def render_openrosa
      render(content_type: "text/xml") if request.format.xml?
      response.headers['X-OpenRosa-Version'] = "1.0"
    end

    # prepares objects and renders the form template
    def prepare_and_render_form
      # render the form template
      @users = User.assigned_to_or_admin(current_mission).by_name
      render(:form)
    end

    def load_form
      @form = Form.find(params[:id])
    end
end
