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
module FormsHelper
  def forms_index_links(forms)
    [link_to_if_auth("Create Form", new_form_path, "forms#create")]
  end
  
  def forms_index_fields
    %w[type name questions published? last_modified downloads responses actions]
  end
    
  def format_forms_field(form, field)
    case field
    when "type" then form.type.name
    when "questions" then form.questions.size
    when "last_modified" then form.updated_at.strftime("%Y-%m-%d %l:%M%p")
    when "responses"
      form.responses.size == 0 ? 0 :
        link_to(form.responses.size, start_searches_path(:query => "formname:\"#{form.name}\"", :class_name => "Response"))
    when "downloads" then form.downloads || 0
    when "published?" then form.published? ? "Yes" : "No"
    when "actions"
      exclude = form.published? ? [:edit, :destroy] : []
      al = action_links(form, :destroy_warning => "Are you sure you want to delete form '#{form.name}'?", 
        :exclude => exclude)
        
      # build confirm message for publish/unpublish link
      if form.published?
        pl_confirm = "Are you sure you want to unpublish form '#{form.name}'? " + 
          "Any changes made to the form may cause problems during data submission."
      else
        pl_confirm = "Are you sure you want to publish form '#{form.name}'? It will immediately be downloadable " + 
          "by all users."
      end
      pl_img = image_tag(form.published? ? "unpublish.png" : "publish.png")
      pl = link_to_if_auth(pl_img, publish_form_path(form), "forms#publish", form, 
        :title => "#{form.published? ? 'Unp' : 'P'}ublish", :confirm => pl_confirm)
      
      cl = link_to_if_auth(image_tag("clone.png"), clone_form_path(form), "forms#clone", form, 
        :title => "Clone", :confirm => "Are you sure you want to clone the form '#{form.name}'?")
      
      (al + pl + cl).html_safe
    else form.send(field)
    end
  end
end
