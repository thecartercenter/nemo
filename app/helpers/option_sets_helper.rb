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
module OptionSetsHelper
  def option_sets_index_links(option_sets)
    [link_to_if_auth("Add new option set", new_option_set_path, "option_sets#create")]
  end
  def option_sets_index_fields
    %w[name options questions published? actions]
  end
  def format_option_sets_field(option_set, field)
    case field
    when "published?" then option_set.published? ? "Yes" : "No"
    when "options" then option_set.sorted_options.collect{|o| o.name_eng}.join(", ")
    when "questions" then option_set.questions.size
    when "actions"
      exclude = option_set.published? ? [:edit, :destroy] : []
      action_links(option_set, :destroy_warning => "Are you sure you want to delete option set '#{option_set.name}'?", 
        :exclude => exclude)
    else option_set.send(field)
    end
  end
end
