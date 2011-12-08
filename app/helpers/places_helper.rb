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
module PlacesHelper
  def places_index_links(places)
    links = []
    unless places.total_entries == 0
      links << link_to_if_auth("View all on map", map_all_places_path, "places#map_all")
    end
    links << link_to_if_auth("Add new place", new_place_path, "places#create")
    links
  end
  def places_index_fields
    %w[type name container latitude longitude actions]
  end
  def format_places_field(place, field)
    case field
    when "name" then place.long_name + ((sn = place.short_name).blank? ? "" : " (#{sn})")
    when "type" then (pt = place.place_type) ? pt.name : ""
    when "latitude" then (lat = place.latitude).nil? ? "" : lat.round(6)
    when "longitude" then (lng = place.longitude).nil? ? "" : lng.round(6)
    when "container" then (pc = place.container) ? pc.full_name : ""
    when "actions"
      alinks = action_links(place, :exclude => :show, 
        :destroy_warning => "Are you sure you want to delete #{place.full_name}?")
      mlink = map_link(place)
      (alinks + mlink).html_safe
    else place.send(field)
    end
  end
  def map_link(place)
    place && place.mappable? ? 
      link_to_if_auth(image_tag("map.png"), map_place_path(place), "places#map", place, :title => "Show on Map") : ""
  end
end
