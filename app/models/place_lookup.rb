class PlaceLookup < ActiveRecord::Base
  has_many(:suggs, :class_name => "PlaceSugg")
  belongs_to(:sugg, :class_name => "PlaceSugg")
  validates(:query, :presence => true)
  
  def self.suggest(query)
    min_level ||= 0
    
    # create the object
    obj = create(:query => query)
    
    # get the matching places (or empty array if there is an error)
    count = 0
    places = Place.search(query)
    places.each{|p| count += 1 if obj.add_suggestion(p); break if count >= 5}
    
    # get the google geolocation suggestions
    GoogleGeolocation.geolocate(query).each{|gg| count += 1 if obj.add_suggestion(gg); break if count >= 10}

    return obj
  end
  
  def self.find_and_update(params)
    pl = params[:id] ? find(params.delete(:id)) : nil
    pl.nil? ? (pl = new(params)) : pl.update_attributes(params)
    pl
  end
  
  # adds a suggestion with the given params, as long as a matching one doesn't already exist
  def add_suggestion(obj)
    suggs.each{|s| return false if s.name == obj.full_name}
    suggs.create(obj.class.name == "Place" ? {:place_id => obj.id} : {:google_geolocation_id => obj.id})
    return true
  end
    
  # creates a new place (and containers if necessary) based on the selected suggestion
  # if no suggestion is selected, returns false and sets errors
  # if suggestion is already in the system, returns false and sets errors
  def spawn
    errors.add_to_base("No suggestion was selected.") and return false if sugg.nil?
    errors.add_to_base("That place is already in the system.") and return false if sugg.obj.is_a?(Place)
    sugg.obj.create_places
    return true
  end
  
  # returns the chosen place, creating it if necessary
  # returns nil if no place chosen
  def choice
    return nil if sugg.nil?
    sugg.obj.is_a?(Place) ? sugg.obj : sugg.obj.create_places.last
  end
end
