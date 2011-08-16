class QuestionsController < ApplicationController
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Question", params[:page])
    # get the questions
    @questions = Question.sorted(@subindex.params)
  end
  
  def choose
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Question", params[:page], "choose")
    @subindex.extras[:form] = Form.find(params[:form_id]) if params[:form_id]
    @form = @subindex.extras[:form]
    @title = "Adding Questions to Form: #{@form.name}"
    @questions = Question.not_in_form(@form, @subindex.params)
    if @questions.empty?
      redirect_to(new_questioning_path(:form_id => @form.id))
    else
      render(:action => :index)
    end
  end
  
  def edit
    @question = Question.find(params[:id])
    @title = "Edit Question: #{@question.code}"
  end
  
  def new
    @question = Question.new
  end
  
  def show
    @question = Question.find(params[:id])
    @title = "Question: #{@question.code}"
  end
  
  def create
    crupdate
  end
  
  def update
    crupdate
  end
  
  def destroy
    @question = Question.find(params[:id])
    begin flash[:success] = @question.destroy && "Question deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  private
    def crupdate
      action = params[:action]
      @question = action == "create" ? Question.new : Question.find(params[:id])
      begin
        @question.update_attributes!(params[:question])
        flash[:success] = "Question #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        @title = "Edit Question: #{@question.code}" if action == "update"
        render(:action => action == "create" ? :new : :edit)
      end
    end
  
end
