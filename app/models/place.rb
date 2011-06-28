class Place < ActiveRecord::Base
  belongs_to(:container, :class_name => "Place")
  has_many(:children, :class_name => "Place", :foreign_key => "container_id")
  before_validation(:set_full_name)
  belongs_to(:place_type)
  before_destroy(:check_assoc)
  
  validates(:long_name, :presence => true)
  validates(:long_name, :format => {:without => /,/, :message => "can't contain commas"})
  validates(:place_type, :presence => true)
  validate(:check_container)
  validate(:check_uniqueness)
  validates(:latitude, :numericality => {:less_than => 90, :greater_than => -90}, :if => Proc.new{|p| p.latitude})
  validates(:longitude, :numericality => {:less_than => 180, :greater_than => -180}, :if => Proc.new{|p| p.longitude})
  
  def self.sorted(params = {})
    params.merge!(:joins => "inner join place_types on places.place_type_id=place_types.id left outer join 
      places container on places.container_id=container.id", 
      :include => [:place_type, :container],
      :order => "place_types.level, places.long_name")
    paginate(:all, params)
  end
  
  def self.bound(places)
    return nil if places.empty?
    {
      :lat_min => places.min_by{|p| p.latitude}.latitude,
      :lat_max => places.max_by{|p| p.latitude}.latitude,
      :lng_min => places.min_by{|p| p.longitude}.longitude,
      :lng_max => places.max_by{|p| p.longitude}.longitude
    }
  end
  
  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_fields
    {:fullname => {:colname => "places.full_name", :default => true, :regexp => true},
     :shortname => {:colname => "places.short_name", :default => true, :regexp => true},
     :container => {:colname => "container.full_name", :default => false, :regexp => true},
     :type => {:colname => "place_types.name", :default => false, :regext => false}}
  end
  
  # gets the lhs, operator, and rhs of a query fragment with the given field and term
  def self.query_fragment(field, term)
    [search_fields[field][:colname], "like", "%#{term}%"]
  end
  
  def self.search_examples
    ["ontario, canada", '"new york"', "california or oregon", "type:state", "container:lebanon"]
  end
  
  # returns places matching the given search query
  # raise an error if the query is invalid (see the Search.conditions method)
  def self.search(query)
    query_cond = Search.create(:query => query, :class_name => self.name).conditions
    find(:all, :include => :place_type, :conditions => query_cond)
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
    end
    
    def check_container
      if place_type && place_type.level == 1 && !container.nil?
        errors.add(:container, "must be blank for countries.")
      elsif place_type && place_type.level > 1 && container.nil?
        errors.add(:container, "can't be blank for a place with type: #{place_type.name}")
      elsif place_type && container && place_type.level <= container.place_type.level
        errors.add(:container, "must be a higher level than #{place_type.name}")
      end
    end
    
    def check_assoc
      unless children.empty?
        raise "'#{full_name}' is a container for other places. You must delete those first."
      end
    end
end
