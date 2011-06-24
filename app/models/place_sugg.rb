class PlaceSugg < ActiveRecord::Base
  belongs_to(:place)
  belongs_to(:google_geolocation)
  def obj
    place || google_geolocation
  end
  def name
    obj.full_name
  end
  def place_type
    obj.place_type
  end
  def source
    obj.class.name == "Place" ? "local" : "google"
  end
end
