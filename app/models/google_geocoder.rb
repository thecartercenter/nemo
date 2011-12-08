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
class GoogleGeocoder
  require 'open-uri'
  BASE_URL = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&"
  
  # queryies the api with the given address and returns a bunch of temporary places
  def self.search(address)
    send_query(:address => address).collect{|r| create_place_from_result(r)}.compact
  end
  
  # queryies the api with the given coords and returns the first place that matches (place is temporary)
  def self.reverse(coords)
    return nil if coords.nil?
    create_place_from_result(send_query(:coords => coords).first)
  end
  
  # looks up and sets the lat/lng of the given place
  def self.lookup_coords(place)
    Rails.logger.debug("Looking up lat/lng for place: #{place.full_name}")
    
    result = send_query(:address => place.full_name).first
    
    return if result.nil?
    
    place.latitude = result['geometry']['location']['lat']
    place.longitude = result['geometry']['location']['lng']
  end
  
  private
    
    # queries the google geocode api with the given params and returns an array of raw results
    def self.send_query(params)
      # build url
      if params[:address]
        # workaround weird CGI parse bug
        params[:address].gsub!(/([^ a-zA-Z0-9_.-]+)/){$1.nil? ? "" : $1}
        url = BASE_URL + "address=" + CGI::escape(params[:address])
      elsif params[:coords]
        url = BASE_URL + "latlng=" + CGI::escape(params[:coords].join(','))
      else
        raise "Invalid geocoder query."
      end

      # run geolocator query
      begin
        Rails.logger.debug("Querying google geolocator with: #{url}")
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
        return reply['results']
      else
        Rails.logger.debug("Google geolocator failed with status '#{reply['status']}'.")
        return []
      end
    end
    
    # creates place object (and objects for its containers, if neccessary) based on a geocoding result
    def self.create_place_from_result(result)
      return nil if result.nil?
      # get the address components
      acomps = parse_address_components(result)
      # loop variable
      container = nil
      # loop over each place type, from country downwards, find_or_creating container.
      PlaceType.except_point.each do |pt|
        # get the address component for this place type
        acomp = acomps[pt]
        unless acomp.nil?
          # find or create
          place = Place.find_or_initialize_by_long_name_and_place_type_id_and_container_id(acomp['long_name'], pt.id, container ? container.id : nil)
          # make it a temporary place if it's new
          place.temporary = true if place.new_record?
          # save to set full_name
          place.save if place.new_record?
          # get the shortname from the address component, if needed
          place.short_name = acomp['short_name'] if place.short_name.nil? && acomp['short_name'] != acomp['long_name']
          # if the place is missing latitude or longitude, try to look it up
          if !place.latitude || !place.longitude
            # copy the lat/lng if it's in the acomp, otherwise geocode it
            acomp['coords'] ? (place.latitude, place.longitude = acomp['coords']) : lookup_coords(place)
          end
          # save the place if we changed it
          place.save if place.changed?
          # save this place as the container for the next place we find/create
          container = place
        end
      end
      # reload the place from the DB in case any weird characters...
      Rails.logger.debug("Reloading place")
      container.reload
      
      # return the last place we found/created
      return container
    end
    
    # returns parsed address components from a geocoding result
    def self.parse_address_components(result)
      addr_components = {}

      # first, build a hash of all components
      raw = {}
      result['address_components'].each_with_index do |acomp, idx|
        # get the primary type
        type = acomp['types'][0]
        # copy the address components (long_name, short_name, types) into hash
        raw[type] = acomp
        # copy the latitude and longitude of the result into the hash if this is the first component
        if idx == 0
          raw[type]['coords'] = [result['geometry']['location']['lat'], result['geometry']['location']['lng']]
        end
      end

      # then try to get a match for each place type
      PlaceType.except_point.each do |pt|
        case pt.level
        when 1 # country
          addr_components[pt] = raw['country']
        when 2 # state/prov
          addr_components[pt] = raw['administrative_area_level_1']
        when 3 # municip
          addr_components[pt] = raw['locality'] || raw['sublocality']
        when 4 # address/landmark
          # try all these
          addr_components[pt] = raw['point_of_interest'] || raw['establishment'] || raw['intersection'] || raw['colloquial_area'] || raw['premise'] ||
            raw['natural_feature'] || raw['airport']
          # if still no dice, look for street number and route
          if !addr_components[pt] && (r = raw['route'])
            route = r['long_name']
            number = (n = raw['street_number']).nil? ? "" : n['long_name'] + " "
            full_addr = "#{number}#{route}"
            addr_components[pt] = {'long_name' => full_addr, 'short_name' => full_addr}
          end
        end
      end

      # normalize multibyte strings in all the components
      addr_components.each do |pt, cmp| 
        next if cmp.nil?
        cmp.each do |k,v|
          cmp[k] = v.normalize.gsub(/([^ a-zA-Z0-9_.-]+)/){$1.nil? ? "" : $1} if v.is_a?(String)
        end
      end

      return addr_components
    end
end