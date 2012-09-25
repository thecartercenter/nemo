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
class QuestioningsController < ApplicationController
  def new
    @qing = Questioning.new_with_question(current_mission, :form_id => params[:form_id])
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
        render_and_setup(action)
      end
    end
    
    def render_and_setup
      @title = @qing.question.code
      @title = "New Question" if @title.blank?
      @option_sets = restrict(OptionSet)
      @question_types = restrict(QuestionType)
      render(:form)
    end
end
