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
module MissionsHelper
  def missions_index_links(missions)
    [link_to_if_auth("Add new Mission", new_mission_path, "missions#create")]
  end
  def missions_index_fields
    %w[name created actions]
  end
  def format_missions_field(mission, field)
    case field
    when "created"
      mission.created_at.to_s(:std_date)
    when "actions"
      action_links(mission, :exclude => [:show], :destroy_warning => "Are you sure you want to delete Mission '#{mission.name}'?")
    else mission.send(field)
    end
  end
end
