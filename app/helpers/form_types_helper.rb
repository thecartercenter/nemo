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
module FormTypesHelper
  def form_types_index_links(form_types)
    [link_to_if_auth("Add new Form Type", new_form_type_path, "form_types#create")]
  end
  def form_types_index_fields
    %w[name actions]
  end
  def format_form_types_field(form_type, field)
    case field
    when "actions"
      action_links(form_type, :destroy_warning => "Are you sure you want to delete Form Type '#{form_type.name}'?")
    else form_type.send(field)
    end
  end
end
