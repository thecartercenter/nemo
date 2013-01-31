class QuestioningsController < ApplicationController
  include QuestionFormable
  
  def new
    @qing = init_qing(:form_id => params[:form_id])
    render_and_setup
  end
  
  def edit
    @qing = Questioning.find(params[:id])
    render_and_setup
  end
  
  def show
    @qing = Questioning.find(params[:id])
    render_and_setup
  end
  
  def destroy
    @qing = Questioning.find(params[:id])
    @form = @qing.form
    begin
      @form.destroy_questionings([@qing])
      flash[:success] = "Question removed successfully." 
    rescue 
      flash[:error] = $!.to_s 
    end
    redirect_to(edit_form_path(@form))
  end
  
  def create; crupdate; end
  
  def update; crupdate; end
  
  private
    def crupdate
      action = params[:action]
      # find or create the questioning
      @qing = action == "create" ? Questioning.new_with_question(current_mission) : Questioning.find(params[:id])
      @qing.question.attributes = params[:questioning].delete(:question)
      # try to save
      begin
        @qing.update_attributes!(params[:questioning])
        flash[:success] = "Question #{action}d successfully."
        redirect_to(edit_form_path(@qing.form))
      rescue ActiveRecord::RecordInvalid
        render_and_setup
      end
    end
    
    def render_and_setup
      @title = @qing.question.code
      @title = "New Question" if @title.blank?
      setup_qing_form_support_objs
      render(:form)
    end
end
