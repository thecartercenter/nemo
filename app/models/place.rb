class Place < ActiveRecord::Base
  belongs_to(:container, :class_name => "Place")
  belongs_to(:place_type)
  has_many(:children, :class_name => "Place", :foreign_key => "container_id")
  has_many(:responses)

  before_validation(:set_full_name)
  before_destroy(:check_assoc)
  
  validates(:long_name, :presence => true)
  validates(:long_name, :format => {:without => /,/, :message => "can't contain commas"})
  validates(:place_type, :presence => true)
  validate(:check_container)
  validate(:check_uniqueness)
  validates(:latitude, :numericality => {:less_than => 90, :greater_than => -90}, :if => Proc.new{|p| p.latitude})
  validates(:longitude, :numericality => {:less_than => 180, :greater_than => -180}, :if => Proc.new{|p| p.longitude})
  
  def self.sorted(params = {})
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
    
    # reverse geolocate and (if successful) convert to place
    gg = GoogleGeolocation.reverse(bits[:coords])
    geo = gg ? gg.create_places.last : nil
    
    # if address is given, override geolocation address value with custom value
    if bits[:addr].blank?
      addr = geo
    else
      # get container (either geo itself if geo is not an address, or otherwise geo's container)
      cont = (geo && geo.is_address?) ? geo.container : geo
      # find/initialize
      addr = Place.find_or_initialize_by_long_name_and_place_type_id_and_container_id(bits[:addr], PlaceType.address.id, cont ? cont.id : nil)
      # if container is nil, this is ok, but set incomplete to false
      addr.incomplete = true if addr.no_container?
      # get longitude & latitude from bits
      addr.latitude, addr.longitude = bits[:coords]
      # set full name and save
      addr.save
      # TODO: don't create orphan places
    end
    addr
  end
  
  # returns places matching the given search query
  # raise an error if the query is invalid (see the Search.conditions method)
  def self.search(query)
    query_cond = Search.create(:query => query, :class_name => self.name).conditions
    find(:all, :include => :place_type, :conditions => query_cond)
  end
  
  def is_address?
    place_type.is_address?
  end
  
  def no_container?
    place_type && place_type.level > 1 && container.nil?
  end
  
  protected
    def check_uniqueness
      if new_record? && self.class.find_by_long_name_and_container_id(long_name, container_id)
        errors.add(:base, "A place with the same name and container already exists.")
      end
    end
      
    def set_full_name(container_full_name = nil)
      if long_name_changed? || container_id_changed? || container_full_name
        container_full_name ||= container ? container.full_name : nil
        self.full_name = long_name + (container_full_name ? ", " + container_full_name : "")
        children.each{|c| c.set_full_name(full_name); c.save}
      end
      return true
    end
    
    def check_container
      if place_type && place_type.level == 1 && !container.nil?
        errors.add(:container, "must be blank for countries.")
      elsif no_container? && !incomplete?
        errors.add(:container, "can't be blank for a place with type: #{place_type.name}")
      elsif place_type && container && place_type.level <= container.place_type.level
        errors.add(:container, "must be a higher level than #{place_type.name}")
      end
    end
    
    def check_assoc
      if !children.empty?
        raise "The place '#{full_name}' is a container for other places. You must delete those first."
      elsif !responses.empty?
        raise "The place '#{full_name}' is associated with one or more responses. You must edit or delete them first."
      end
    end
end
