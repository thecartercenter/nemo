class QuestionsController < ApplicationController
  # this Concern includes routines for building question/ing forms
  include QuestionFormable

  load_and_authorize_resource

  def index
    @questions = @questions.with_answer_counts.by_code.paginate(:page => params[:page], :per_page => 25)
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
    @question.assign_attributes(params[:question])
    create_or_update
  end
  
  def destroy
    destroy_and_handle_errors(@question)
    redirect_to(:action => :index)
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