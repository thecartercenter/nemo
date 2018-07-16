class QuestionsController < ApplicationController
  include StandardImportable, Searchable, BatchProcessable

  include Parameters

  # this Concern includes routines for building question/ing forms
  include QuestionFormable

  load_and_authorize_resource

  def index
    @questions = apply_search_if_given(Question, @questions)
    @tags = Tag.mission_tags(@current_mission)
    @questions = @questions.includes(:tags).by_code.paginate(:page => params[:page], :per_page => 25)
    load_importable_objs
  end

  def show
    prepare_and_render_form
  end

  def new
    prepare_and_render_form
  end

  def edit
    prepare_and_render_form
  end

  def create
    @question.is_standard = true if current_mode == 'admin'

    permitted_params = question_params

    # Convert tag string from TokenInput to array
    @question.tag_ids = (permitted_params[:tag_ids] || '').split(',')

    # Convert tags_attributes hidden inputs to create new tags (why doesn't this happen automatically here?)
    @question.tags_attributes = permitted_params[:tags_attributes] || []

    create_or_update
  end

  def update
    permitted_params = question_params

    # Convert tag string from TokenInput to array
    permitted_params[:tag_ids] = permitted_params[:tag_ids].split(',')

    # assign attribs and validate now so that normalization runs before authorizing and saving
    @question.assign_attributes(permitted_params)
    @question.valid?

    # authorize special abilities
    authorize!(:update_code, @question) if @question.code_changed?
    authorize!(:update_core, @question) if @question.core_changed?

    create_or_update
  end

  def destroy
    destroy_and_handle_errors(@question)
    redirect_to(index_url_with_context)
  end

  def bulk_destroy
    @questions = load_selected_objects(Question)
    destroyer = BatchDestroy.new(@questions, current_user, current_ability)
    out = destroyer.destroy!

    success = []
    success << t("question.bulk_destroy_deleted", count: out[:destroyed]) if out[:destroyed].positive?
    success << t("question.bulk_destroy_skipped", count: out[:skipped]) if out[:skipped].positive?

    flash[:success] = success.join(" ") unless success.empty?

    redirect_to(index_url_with_context)
  end

  def audio_prompt
    authorize! :show, @question

    decorated_question = Odk::QuestionDecorator.decorate(@question)

    send_file decorated_question.audio_prompt.path,
      type: decorated_question.audio_prompt_content_type,
      disposition: "attachment",
      filename: decorated_question.unique_audio_prompt_filename
  end

  private

  # creates/updates the question
  def create_or_update
    if @question.save
      set_success_and_redirect(@question)
    else
      flash.now[:error] = I18n.t('activerecord.errors.models.question.general')
      prepare_and_render_form
    end
  end

  # prepares objects for and renders the form template
  def prepare_and_render_form
    # this method lives in the QuestionFormable concern
    setup_question_form_support_objs
    render(:form)
  end

  def question_params
    params.require(:question).permit(whitelisted_question_params(params[:question]))
  end
end
