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
module BrodcastsHelper
  def broadcasts_index_links(broadcasts)
    [link_to_if_auth("Send Broadcast", new_broadcast_path, "broadcasts#create")]
  end
  
  def broadcasts_index_fields
    %w[to medium sent_at errors? message actions]
  end
    
  def format_broadcasts_field(broadcast, field)
    case field
    when "to" then "#{broadcast.recipients.count} users"
    when "medium" then broadcast.medium.capitalize
    when "message" then truncate(broadcast.body, :length => 100)
    when "sent_at" then broadcast.created_at.to_s(:std_datetime)
    when "errors?" then broadcast.send_errors.blank? ? "No" : "Yes"
    when "actions" then action_links(broadcast, :exclude => [:edit, :destroy])
    else broadcast.send(field)
    end
  end
end
