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
module QuestioningsHelper
  def format_questionings_field(qing, field)
    case field
    when "rank" then controller.action_name == "show" ? qing.rank : text_field_tag("rank[#{qing.id}]", qing.rank, :class => "rank_box")
    when "code", "title", "type" then format_questions_field(qing.question, field)
    when "condition?" then qing.has_condition? ? "Yes" : "No"
    when "required?", "hidden?" then qing.send(field) ? "Yes" : "No"
    when "actions"
      exclude = ((qing.published? || controller.action_name == "show") ? [:edit, :destroy] : [])
      action_links(qing, :destroy_warning => "Are you sure you want to remove question '#{qing.code}' from this form", :exclude => exclude)
    else qing.send(field)
    end
  end
  
  def questionings_index_links(qings)
    links = []
    if controller.action_name == "edit"
      links << link_to("Add questions", choose_questions_path(:form_id => @form.id))
      if qings.size > 0
        links << batch_op_link(:name => "Remove selected",
          :confirm => "Are you sure you want to remove these ### question(s) from the form?",
          :action => "forms#remove_questions", :id => @form.id)
        
        # add publish and print links
        links << link_to("Publish form", publish_form_path(qings.first.form))
      end
    end
    
    # can print from show action
    if qings.size > 0
      links << link_to("Print form", "#", :onclick => "Form.print(#{qings.first.form.id}); return false;") + " " +
        loading_indicator(:id => qings.first.form.id)
    end
      
    links
  end
  
  def questionings_index_fields
    %w[rank code title type condition? required? hidden? actions]
  end
end
