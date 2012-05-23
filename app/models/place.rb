require 'place_lookupable'

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
class Place < ActiveRecord::Base
  include PlaceLookupable
  
  belongs_to(:container, :class_name => "Place")
  belongs_to(:place_type)
  has_many(:children, :class_name => "Place", :foreign_key => "container_id", :dependent => :destroy)
  has_many(:responses)
  has_one(:place_creator)
  belongs_to(:point, :class_name => "Place")
  belongs_to(:address, :class_name => "Place")
  belongs_to(:locality, :class_name => "Place")
  belongs_to(:state, :class_name => "Place")
  belongs_to(:country, :class_name => "Place")

  before_validation(:clean_commas)
  before_validation(:set_full_name)
  before_save(:update_container_shortcuts)
  before_save(:check_temporary)
  before_destroy(:check_assoc)
  
  validates(:long_name, :presence => true)
  validates(:long_name, :format => {:without => /,/, :message => "can't contain commas"})
  validates(:place_type, :presence => true)
  validate(:check_container)
  validate(:check_uniqueness)
  validates(:latitude, :numericality => {:less_than => 90, :greater_than => -90}, :if => Proc.new{|p| p.latitude})
  validates(:longitude, :numericality => {:less_than => 180, :greater_than => -180}, :if => Proc.new{|p| p.longitude})
  
  default_scope(includes(:place_type, :container).order("place_types.level, places.long_name"))
  scope(:permanent, where(:temporary => false))
  
  def self.bound(places)
    return nil if places.empty?
    {
      :lat_min => [-89, places.min_by{|p| p.latitude}.latitude].max,
      :lat_max => [89, places.max_by{|p| p.latitude}.latitude].min,
      :lng_min => [-180, places.min_by{|p| p.longitude}.longitude].max,
      :lng_max => [180, places.max_by{|p| p.longitude}.longitude].min
    }
  end
  
  def self.search_qualifiers
    [
      Search::Qualifier.new(:label => "fullname", :col => "places.full_name", :default => true, :partials => true),
      Search::Qualifier.new(:label => "shortname", :col => "places.short_name", :default => true, :partials => true),
      Search::Qualifier.new(:label => "container", :col => "containers_places.full_name", :assoc => :container, :partials => true),
      Search::Qualifier.new(:label => "type", :col => "place_types.name", :assoc => :place_type)
    ]
  end
  
  def self.search_examples
    ["ontario, canada", '"new york"', "california or oregon", "type:state", "container:lebanon"]
  end
  
  def self.find_or_create_with_bits(bits)
    return nil unless bits[:coords]
    
    # reverse geolocate to get container
    container = GoogleGeocoder.reverse(bits[:coords])
    
    # if no place name is given, just return the container
    return container if bits[:place_name].blank?

    # find/init a point place based on place_name
    point = Place.find_or_initialize_by_long_name_and_place_type_id_and_container_id(
      bits[:place_name], PlaceType.point.id, container ? container.id : nil)
    # get longitude & latitude from bits if not already set
    point.latitude, point.longitude = bits[:coords] unless point.latitude && point.longitude
    # set full name and save if necessary
    point.save if point.changed?
    
    return point
  end
  
  # returns places matching the given search query
  # raise an error if the query is invalid (see the Search.conditions method)
  def self.search(str)
    Search::Search.find_or_create(:str => "\"#{str}\"", :class_name => self.name).apply(permanent)
  end
  
  # searches existing, non-temporary places and geocoding services for places matching query
  def self.lookup(query)
    return [] if query.blank?
    
    # clean up old temp places
    #cleanup
    
    # get existing places
    places = search(query)
    
    # get places from geocoding service
    places += configatron.geocoder.search(query)
    
    # reject any duplicates
    places.uniq{|p| p.full_name}
  end
  
  # removes temporary places that are more than 1/2 hour old
  def self.cleanup
    delete_all(["temporary = 1 and created_at < ?", Time.now - 30.minutes])
  end
  
  def is_address?
    place_type.is_address?
  end
  
  def no_container?
    place_type && place_type.level > 1 && container.nil?
  end
  
  def mappable?
    latitude && longitude
  end
  
  def bounds
    {
      :lat_min => [-89, latitude - 5].max,
      :lat_max => [89, latitude + 5].min,
      :lng_min => [-180, longitude - 5].max,
      :lng_max => [180, longitude + 5].min
    }
  end
  
  def type_code
    place_type ? place_type.short_name : nil
  end
  
  def place_field_name; "container"; end
    
  protected
    def check_uniqueness
      if new_record? && self.class.find_by_long_name_and_container_id(long_name, container_id)
        errors.add(:base, "A place with the same name and container already exists.")
      end
    end
      
    def set_full_name(container_full_name = nil)
      if long_name_changed? || container_id_changed? || container_full_name
        container_full_name ||= container ? container.full_name : nil
        self.full_name = long_name + (!container_full_name.blank? ? ", " + container_full_name : "")
        children.each{|c| c.set_full_name(full_name); c.save}
      end
      return true
    end
    
    def check_container
      if place_type && place_type.level == 1 && !container.nil?
        errors.add(:container, "must be blank for countries.")
      elsif no_container?
        errors.add(:container, "can't be blank for a place with type: #{place_type.name}")
      elsif place_type && container && place_type.level <= container.place_type.level
        errors.add(:container, "must be a higher level than #{place_type.name}")
      end
    end
    
    def update_container_shortcuts(updated_container = nil)
      # reload relevant associations if necessary
      container.reload if container_id_changed?
      place_type.reload if place_type_id_changed?
      
      if container_id_changed? || place_type_id_changed? || updated_container
        # prefer the passed container
        cnt = updated_container || Place.find_by_id(container_id)
        # update own shortcuts by copying from new container
        PlaceType.shortcut_codes.each{|c| self.send("#{c}_id=", cnt ? cnt.send("#{c}_id") : nil)}
        # set shortcut to container itself
        self.send("#{cnt.place_type.short_name}_id=", cnt.id) unless cnt.nil?
        
        # tell all children to update their redundant links
        children.each{|c| c.update_container_shortcuts(self); c.save}
      end
      return true
    end
    
    def clean_commas
      self.long_name.gsub!(",", "") if long_name
    end
    
    def check_temporary
      # if we are non-temporary, ensure all containers are non temporary also
      container.update_attributes(:temporary => false) if temporary == false && container
    end
      
    
    def check_assoc
      if type_code && self.class.send("find_by_#{type_code}_id_and_temporary", id, 0)
        raise "The place '#{full_name}' is a container for other places. You must delete those first."
      elsif !responses.empty?
        raise "The place '#{full_name}' is associated with one or more responses. You must edit or delete them first."
      end
    end
end
