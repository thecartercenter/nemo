class GoogleGeolocation < ActiveRecord::Base
  require 'open-uri'
  BASE_URL = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address="
  belongs_to(:place_type)
  before_create(:parse_result)
  
  # queries the google geocode api with the given address and returns a bunch of objects
  def self.geolocate(query)
    puts "query: #{query}"
    url = BASE_URL + CGI::escape(query.to_s)
    
    # run geolocator query
    begin
      Rails.logger.debug("Querying google geolocator with: #{query}")
      json = open(url){|f| f.read} 
    rescue SocketError
      Rails.logger.debug("Google geolocator failed with: #{$!.to_s}")
      return []
    end
    
    # decode JSON
    reply = ActiveSupport::JSON.decode(json)
    
    # if status is defined OK
    if reply['status'] == "OK"
      Rails.logger.debug("Google geolocator returned #{reply['results'].size} results.")
    
      # parse results and return
      return reply['results'].collect{|r| create(:result => r)}.compact
    else
      Rails.logger.debug("Google geolocator failed with status '#{reply['status']}'.")
      return []
    end
  end
  
  # reconstructs the result of the query to the API from stored json
  def result
    @result ||= ActiveSupport::JSON.decode(json)
  end
  
  def result=(r)
    @result = r
    self.json = r.to_json
  end
  
  # converts this object into one or more Place objects.
  # creates parents as necessary
  def create_places
    # temp variable for the immediate container
    container = nil
    # array to hold all the created places
    places = []
    # loop over each place type, from country downwards, find_or_creating container. return the immediate container.
    PlaceType.sorted.each do |pt|
      # get the address component for this place type
      ac = addr_components[pt]
      unless ac.nil?
        # find or create
        place = Place.find_or_create_by_long_name_and_place_type_id_and_container_id(ac['long_name'], pt.id, container ? container.id : nil)
        # get the shortname from the address component, if needed
        place.short_name = ac['short_name'] if place.short_name.nil? && ac['short_name'] != ac['long_name']
        # if the place is missing latitude or longitude, try to look it up
        if !place.latitude || !place.longitude
          puts "geolocating #{place.full_name}"
          unless (ggs = self.class.geolocate(place.full_name)).empty?
            place.latitude = ggs.first.latitude
            place.longitude = ggs.first.longitude
          end
        end
        place.save(:validate => false)
        places << place
        container = place
      end
    end
    places
  end
  
  # returns the address components from the query result
  def addr_components
    # if we've already parsed it, return it
    return @addr_components if @addr_components
    
    # otherwise, parse
    @addr_components = {}
    
    # first, build a hash of all components
    raw = {}
    result['address_components'].each{|ac| raw[ac['types'][0]] = ac}
    
    # then try to get a match for each place type
    PlaceType.sorted.each do |pt|
      case pt.level
      when 1 # country
        @addr_components[pt] = raw['country']
      when 2 # state/prov
        @addr_components[pt] = raw['administrative_area_level_1']
      when 3 # municip
        @addr_components[pt] = raw['locality'] || raw['sublocality']
      when 4 # address/landmark
        # try all these
        @addr_components[pt] = raw['point_of_interest'] || raw['establishment'] || raw['intersection'] || raw['colloquial_area'] || raw['premise'] ||
          raw['natural_feature'] || raw['airport']
        # if still no dice, look for street number and route
        if !@addr_components[pt] && (r = raw['route'])
          route = r['long_name']
          number = (n = raw['street_number']).nil? ? "" : n['long_name'] + " "
          full_addr = "#{number}#{route}"
          @addr_components[pt] = {'long_name' => full_addr, 'short_name' => full_addr}
        end
      end
    end

    # normalize multibyte strings in all the components
    @addr_components.each do |pt,comp|
      next if comp.nil?
      comp.each do |key, value| 
        comp[key] = value.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'') if value.is_a?(String)
      end
    end
  
    @addr_components
  end
  
  def to_s
    full_name
  end
  
  private
    # parses several fields out of a result from the google geocoder
    def parse_result
      # build full name. #loop over all placetypes, getting address components
      self.full_name = PlaceType.sorted.reverse.collect do |pt| 
        if (ac = addr_components[pt])
          # set the place type
          self.place_type_id = pt.id if self.place_type_id.nil?
          # return the long_name from the address component
          ac['long_name']
        else
          nil
        end
      end.compact.join(", ")
      # save the latitude and longitude
      self.latitude = result['geometry']['location']['lat']
      self.longitude = result['geometry']['location']['lng']
      # safe the formatted address
      self.formatted_addr = result['formatted_address']
    end
end