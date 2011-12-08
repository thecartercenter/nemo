# Elmo - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# Elmo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Elmo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Elmo.  If not, see <http://www.gnu.org/licenses/>.
# 
module QuestionsHelper
  def format_questions_field(q, field)
    case field
    when "name" then q.name_eng
    when "type" then q.type.long_name
    when "forms" then q.forms.size
    when "answers" then q.answers.size
    when "published?" then q.published? ? "Yes" : "No"
    when "actions"
      exclude = q.published? ? [:edit, :destroy] : []
      action_links(q, :destroy_warning => "Are you sure you want to delete question '#{q.code}'", :exclude => exclude)
    else q.send(field)
    end
  end
  
  def questions_index_fields
    choose_mode = controller.action_name == "choose"
    %w[code name type forms answers] + (choose_mode ? [] : %w[published? actions])
  end
  
  def questions_index_links(questions)
    choose_mode = controller.action_name == "choose"
    links = []
    if choose_mode
      unless @questions.total_entries == 0
        links << batch_op_link(:name => "Add selected questions to form", :action => "forms#add_questions", :id => @form.id)
      end
      links << link_to_if_auth("Create new question", new_questioning_path(:form_id => @form.id), "questionings#create")
    else
      links << link_to_if_auth("Create new question", new_question_path, "questions#create")
    end
    links
  end
end
