class Mission < ActiveRecord::Base
  before_validation(:create_compact_name)
  
  validates(:name, :presence => true)
  validates(:name, :format => {:with => /^[a-z][a-z0-9 ]*$/i, :message => "can only contain letters, numbers, and spaces"},
                   :length => {:minimum => 3, :maximum => 16},
                   :if => Proc.new{|m| !m.name.blank?})
  validate(:compact_name_unique)
  
  scope(:sorted_by_name, order("name"))
  scope(:sorted_recent_first, order("created_at DESC"))
  
  def self.select_options(list = nil)
    (list || all).collect{|m| [m.name, m.id]}
  end
  
  private
    def create_compact_name
      self.compact_name = name.gsub(" ", "").downcase
    end
    
    def compact_name_unique
      if !name.blank? && matching = (self.class.where(:compact_name => compact_name).all - [self]).first
        errors.add(:name, "is too much like the existing mission '#{matching.name}'")
      end
    end
end
