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
end
