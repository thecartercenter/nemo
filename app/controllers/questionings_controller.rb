class QuestioningsController < ApplicationController
  def edit
    @title = "Edit Question"
    @qing = Questioning.find(params[:id])
    set_js
  end
  
  def update
    @title = "Edit Question"
    @qing = Questioning.find(params[:id])
    @qing.question.attributes = params[:questioning].delete(:question)
    if @qing.update_attributes(params[:questioning])
      flash[:success] = "Question updated successfully."
      redirect_to(:action => :edit)
    else
      set_js
      render(:action => :edit)
    end
  end
  
  private
    #def crupdate
    #  action = params[:action]
    #  # find or create the questioning
    #  @qing = action == "create" ? Questioning.new : Questioning.find(params[:id])
    #  # try to save
    #  begin
    #    @resp.update_attributes!(params[:response])
    #    flash[:success] = "Response #{action}d successfully."
    #    redirect_to(edit_response_path(@resp))
    #  rescue ActiveRecord::RecordInvalid
    #    set_js
    #    render(:action => action == "create" ? :new : :edit)
    #  end
    #end
    
    def set_js
      @js << 'questions'
    end
end
