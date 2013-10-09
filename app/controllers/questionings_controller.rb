class QuestioningsController < ApplicationController
  # this Concern includes routines for building question/ing forms
  include QuestionFormable
  
  # init the questioning object in a special way before load_resource
  before_filter :init_qing_with_form_id, :only => [:create]
  
  # authorization via cancan
  load_and_authorize_resource
  
  def edit
    prepare_and_render_form
  end
  
  def show
    prepare_and_render_form
  end
  
  def create
    if @questioning.save
      set_success_and_redirect(@questioning.question, :to => edit_form_path(@questioning.form))
    else
      prepare_and_render_form
    end
  end
  
  def update
    # strip out condition fields if they're blank and questioning has no existing condition
    # this prevents an empty condition from getting initialized and then deleted again
    params[:questioning].delete(:condition_attributes) if params[:questioning][:condition_attributes][:ref_qing_id].blank? && !@questioning.condition

    # assign attributes first, then check auth
    @questioning.assign_attributes(params[:questioning])

    authorize!(:update_core, @questioning) if @questioning.core_changed?
    authorize!(:update_core, @questioning.question) if @questioning.question.core_changed?

    if @questioning.save
      set_success_and_redirect(@questioning.question, :to => edit_form_path(@questioning.form))
    else
      prepare_and_render_form
    end
  end

  def destroy
    destroy_and_handle_errors(@questioning)
    redirect_to(edit_form_url(@questioning.form))
  end
  
  private
    # prepares objects for and renders the form template
    def prepare_and_render_form
      # this method lives in the QuestionFormable concern
      setup_qing_form_support_objs
      render(:form)
    end
    
    # inits the questioning using the proper method in QuestionFormable
    def init_qing_with_form_id
      authorize! :create, Questioning
      init_qing(params[:questioning])
    end
end
