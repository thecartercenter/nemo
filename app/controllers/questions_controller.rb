# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
class QuestionsController < ApplicationController
  def index
    @questions = apply_filters(Question)
  end
  
  def choose
    @form = Form.find(params[:form_id])
    @title = "Adding Questions to Form: #{@form.name}"
    @questions = apply_filters(Question.not_in_form(@form))
    if @questions.empty?
      redirect_to(new_questioning_path(:form_id => @form.id))
    else
      render(:action => :index)
    end
  end
  
  def new
    @question = Question.for_mission(current_mission).new
    render_form
  end
  
  def edit
    @question = Question.find(params[:id])
    @title = "Edit Question: #{@question.code}"
    render_form
  end
  
  def show
    @question = Question.find(params[:id])
    @title = "Question: #{@question.code}"
    render_form
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
      @question = action == "create" ? Question.for_mission(current_mission).new : Question.find(params[:id])
      begin
        @question.update_attributes!(params[:question])
        flash[:success] = "Question #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        @title = "Edit Question: #{@question.code}" if action == "update"
        render_form
      end
    end
  
    def render_form
      @title = @question.code
      @title = "New Question" if @title.blank?
      @option_sets = restrict(OptionSet)
      @question_types = restrict(QuestionType)
      render(:form)
    end
end
