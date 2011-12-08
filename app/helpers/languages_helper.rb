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
module LanguagesHelper
  def languages_index_fields
    %w[name code active? actions]
  end
  def languages_index_links(languages)
    [link_to_if_auth("Add new language", new_language_path, "languages#create")]
  end
  def format_languages_field(language, field)
    case field
    when "active?" then language.active? ? "Yes" : "No"
    when "actions"
      action_links(language, :exclude => :show, 
        :destroy_warning => "Are you sure you want to delete #{language.name}?")
    else language.send(field)
    end
  end
end
