class GoogleGeolocation < ActiveRecord::Base
  require 'open-uri'
  BASE_URL = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address="
  
  belongs_to(:place_type)
  
  # queries the google geocode api with the given address and returns
  # the results as Place objects
  def self.geolocate(query)
    url = BASE_URL + URI.escape(query)
    
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
      return reply['results'].collect{|r| create_from_result(r)}.compact
    else
      Rails.logger.debug("Google geolocator failed with status '#{reply['status']}'.")
      return []
    end
  end
  
  def self.create_from_result(result)
    gg = new(:json => result.to_json)
    gg.build_full_name_and_type
    gg.save
    gg
  end
  
  # reconstructs the result of the query to the API from stored json
  def result
    @result ||= ActiveSupport::JSON.decode(json)
  end
  
  # builds the fully qualified name based on the query result
  # this is part of the process of creating an instance of the class
  def build_full_name_and_type
    self.full_name = PlaceType.sorted.reverse.collect do |pt| 
      if (ac = addr_components[pt])
        self.place_type_id = pt.id if self.place_type_id.nil?
        ac['long_name']
      else
        nil
      end
    end.compact.join(", ")
  end
  
  def create_places
    # loop over each address component, find_or_creating container. return the immediate container.
    container = nil
    places = []
    PlaceType.sorted.each do |pt|
      # get the address component
      acomp = addr_components[pt]
      # find or create
      unless acomp.nil?
        place = Place.find_or_create_by_long_name_and_place_type_id_and_container_id(acomp['long_name'], pt.id, container ? container.id : nil)
        place.short_name = acomp['short_name'] if place.short_name.nil? && acomp['short_name'] != acomp['long_name']
        place.save(false)
        places << place
        container = place
      end
    end
    places
  end
  
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

    # normalize all the components
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
end