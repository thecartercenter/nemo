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
module UsersHelper
  def users_index_fields
    %w[name login email language role main_phone alternate_phone active? actions]
  end
  def format_users_field(user, field)
    case field
    when "email" then mail_to(user.email)
    when "main_phone" then user.phone
    when "alternate_phone" then user.phone2
    when "language" then user.language.name
    when "active?" then user.active? ? "Yes" : "No"
    when "actions"
      action_links(user, :exclude => :show,
        :destroy_warning => "Are you sure you want to delete #{user.name}?")
    else user.send(field)
    end
  end
  def users_index_links(users)
    [
      batch_op_link(:name => "Send Broadcast", :action => "broadcasts#new_with_users"),
      batch_op_link(:name => "Export as vCard", :action => "users#export", :format => :vcf),
      link_to_if_auth("Create New User", new_user_path, "users#create"),
      link_to_if_auth("Create Multiple Users", new_user_batch_path, "users#create")
    ]
  end
end
