require 'place_lookupable'
class PlaceCreator < ActiveRecord::Base
  include PlaceLookupable
  belongs_to(:place)
  def place_field_name; "place"; end
end
