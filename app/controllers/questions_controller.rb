class QuestionsController < ApplicationController
  include StandardImportable

  # this Concern includes routines for building question/ing forms
  include QuestionFormable

  load_and_authorize_resource

  def index
    # do search if applicable
    if params[:search].present?
      begin
        @questions = Question.do_search(@questions, params[:search])
      rescue Search::ParseError
        flash.now[:error] = $!.to_s
        @search_error = true
      end
    end

    @tags = Tag.mission_tags(@current_mission)

    @questions = @questions.includes(:tags).with_assoc_counts.by_code.paginate(:page => params[:page], :per_page => 25)
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

    # Convert tag string from TokenInput to array
    @question.tag_ids = (params[:question][:tag_ids] || '').split(',')

    # Convert tags_attributes hidden inputs to create new tags (why doesn't this happen automatically here?)
    @question.tags_attributes = params[:question][:tags_attributes] || []

    create_or_update
  end

  def update
    # Convert tag string from TokenInput to array
    params[:question][:tag_ids] = params[:question][:tag_ids].split(',')

    # assign attribs and validate now so that normalization runs before authorizing and saving
    @question.assign_attributes(params[:question])
    @question.valid?

    # authorize special abilities
    authorize!(:update_code, @question) if @question.code_changed?
    authorize!(:update_core, @question) if @question.core_changed?

    create_or_update
  end

  def destroy
    destroy_and_handle_errors(@question)
    redirect_to(index_url_with_page_num)
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

end
