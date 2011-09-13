require 'place_lookupable'
class PlaceCreator < ActiveRecord::Base
  include PlaceLookupable
  def place_field_name; "place"; end
end
