class QuestionsController < ApplicationController
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Question", params[:page])
    # get the questions
    @questions = Question.sorted(@subindex.params)
  end
  
  def edit
    @question = Question.find(params[:id])
    set_js
  end
  
  def new
    @question = Question.new
    set_js
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
        set_js
        render(:action => action == "create" ? :new : :edit)
      end
    end
  
    def set_js
      @js << 'questions'
    end
end
