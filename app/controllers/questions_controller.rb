class QuestionsController < ApplicationController
  include StandardImportable
  
  # this Concern includes routines for building question/ing forms
  include QuestionFormable
  
  load_and_authorize_resource

  def index
    @questions = @questions.with_assoc_counts.by_code.paginate(:page => params[:page], :per_page => 25)
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
    create_or_update
  end
  
  def update
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