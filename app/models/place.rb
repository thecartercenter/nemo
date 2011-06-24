class Place < ActiveRecord::Base
  belongs_to(:place_lookup)
  belongs_to(:container, :class_name => "Place")
  has_many(:children, :class_name => "Place", :foreign_key => "container_id")
  before_validation(:set_full_name)
  belongs_to(:place_type)
  
  validates(:long_name, :presence => true)
  validates(:long_name, :format => {:without => /,/, :message => "can't contain commas"})
  validates(:place_type, :presence => true)
  validate(:check_container)
  validate(:check_uniqueness)
  validates(:latitude, :numericality => {:less_than => 90, :greater_than => -90}, :if => Proc.new{|p| p.latitude})
  validates(:longitude, :numericality => {:less_than => 180, :greater_than => -180}, :if => Proc.new{|p| p.longitude})
  
  def self.default
    place = new(:is_temp => true)
    place.place_lookup = PlaceLookup.new
    place
  end

  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_fields
    {:full_name => {:default => true, :regexp => true},
     :short_name => {:default => true, :regexp => true}}
  end
  
  # gets the lhs, operator, and rhs of a query fragment with the given field and term
  def self.query_fragment(field, term)
    ["places.#{field.to_s}", "like", "%#{term}%"]
  end
  
  # returns places matching the given search query
  # raise an error if the query is invalid (see the Search.conditions method)
  def self.search(query)
    query_cond = Search.create(:query => query, :class_name => self.name).conditions
    find(:all, :include => :place_type, :conditions => query_cond)
  end
  
  protected
    def check_uniqueness
      unless self.class.find_by_long_name_and_container_id(long_name, container_id).nil?
        errors.add(:base, "A place with the same name and container already exists.")
      end
    end
      
    def set_full_name(container_full_name = nil)
      if long_name_changed? || container_full_name
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
end
