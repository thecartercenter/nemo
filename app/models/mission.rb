class Mission < ActiveRecord::Base
  has_many(:responses)
  has_many(:forms)
  has_many(:reports, :class_name => "Report::Report")
  has_many(:options)
  has_many(:option_sets)
  has_many(:questions)
  has_many(:form_types)
  has_many(:broadcasts)
  has_many(:settings)
  
  before_validation(:create_compact_name)
  before_destroy(:check_assoc)
  
  validates(:name, :presence => true)
  validates(:name, :format => {:with => /^[a-z][a-z0-9 ]*$/i, :message => "can only contain letters, numbers, and spaces"},
                   :length => {:minimum => 3, :maximum => 32},
                   :if => Proc.new{|m| !m.name.blank?})
  validate(:compact_name_unique)
  
  scope(:sorted_by_name, order("name"))
  scope(:sorted_recent_first, order("created_at DESC"))
  scope(:for_user, lambda{|u| where("missions.id IN (SELECT mission_id FROM assignments WHERE user_id = ?)", u.id)})
  
  private
    def create_compact_name
      self.compact_name = name.gsub(" ", "").downcase
    end
    
    def compact_name_unique
      if !name.blank? && matching = (self.class.where(:compact_name => compact_name).all - [self]).first
        errors.add(:name, "is too much like the existing mission '#{matching.name}'")
      end
    end
    
    def check_assoc
      to_check = [:responses, :forms, :reports, :options, :option_sets, :questions, :form_types, :broadcasts, :settings]
      to_check.each{|a| raise "This mission has associated objects and can't be deleted." unless self.send(a).empty?}
    end
end
