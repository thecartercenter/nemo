module PlacesHelper
  def format_places_field(place, field)
    case field
    when "name" then place.long_name + ((sn = place.short_name).blank? ? "" : " (#{sn})")
    when "type" then (pt = place.place_type) ? pt.name : ""
    when "latitude" then (lat = place.latitude).nil? ? "" : lat.round(6)
    when "longitude" then (lng = place.longitude).nil? ? "" : lng.round(6)
    when "container" then (pc = place.container) ? pc.full_name : ""
    when "actions"
      link_to("Edit", edit_place_path(place)) + " | " +
        link_to("Delete", place, :method => :delete, :confirm => "Are you sure you want to delete #{place.full_name}?")
    else place.send(field)
    end
  end
end
