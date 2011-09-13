require 'place_lookupable'

class Place < ActiveRecord::Base
  include PlaceLookupable
  
  belongs_to(:container, :class_name => "Place")
  belongs_to(:place_type)
  has_many(:children, :class_name => "Place", :foreign_key => "container_id")
  has_many(:responses)

  before_validation(:set_full_name)
  before_save(:update_container_shortcuts)
  before_destroy(:check_assoc)
  
  validates(:long_name, :presence => true)
  validates(:long_name, :format => {:without => /,/, :message => "can't contain commas"})
  validates(:place_type, :presence => true)
  validate(:check_container)
  validate(:check_uniqueness)
  validates(:latitude, :numericality => {:less_than => 90, :greater_than => -90}, :if => Proc.new{|p| p.latitude})
  validates(:longitude, :numericality => {:less_than => 180, :greater_than => -180}, :if => Proc.new{|p| p.longitude})
  
  def self.sorted(params = {})
    params[:conditions] = "(#{params[:conditions]}) and places.temporary != 1"
    params.merge!(:order => "place_types.level, places.long_name")
    paginate(:all, params)
  end
  
  def self.bound(places)
    return nil if places.empty?
    {
      :lat_min => [-89, places.min_by{|p| p.latitude}.latitude].max,
      :lat_max => [89, places.max_by{|p| p.latitude}.latitude].min,
      :lng_min => [-180, places.min_by{|p| p.longitude}.longitude].max,
      :lng_max => [180, places.max_by{|p| p.longitude}.longitude].min
    }
  end
  
  def self.default_eager
    [:place_type, :container]
  end
  
  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_fields
    {:fullname => {:colname => "places.full_name", :default => true, :regexp => true},
     :shortname => {:colname => "places.short_name", :default => true, :regexp => true},
     :container => {:colname => "containers_places.full_name", :default => false, :regexp => true},
     :type => {:colname => "place_types.name", :default => false, :regexp => false}}
  end
  
  # gets the lhs, operator, and rhs of a query fragment with the given field and term
  def self.query_fragment(field, term)
    [search_fields[field][:colname], "like", "%#{term}%"]
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
  def self.search(query)
    query_cond = Search.create(:query => query, :class_name => self.name).conditions
    find(:all, :include => :place_type, :conditions => "(#{query_cond}) and temporary != 1")
  end
  
  # searches existing, non-temporary places and geocoding services for places matching query
  def self.lookup(query)
    return [] if query.blank?
    
    # clean up old temp places
    cleanup
    
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
    
    def check_assoc
      if !children.empty?
        raise "The place '#{full_name}' is a container for other places. You must delete those first."
      elsif !responses.empty?
        raise "The place '#{full_name}' is associated with one or more responses. You must edit or delete them first."
      end
    end
end
