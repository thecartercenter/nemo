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
module OptionsHelper
  def options_index_links(options)
    [link_to_if_auth("Add new option", new_option_path, "options#create")]
  end
  def options_index_fields
    %w[name value published? actions]
  end
  def format_options_field(option, field)
    case field
    when "name" then option.name_eng
    when "published?" then option.published? ? "Yes" : "No"
    when "actions"
      exclude = option.published? ? [:edit, :destroy] : []
      action_links(option, :destroy_warning => "Are you sure you want to delete option '#{option.name_eng}'?", 
        :exclude => exclude)
    else option.send(field)
    end
  end
end
