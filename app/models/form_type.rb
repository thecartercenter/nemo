class FormType < ActiveRecord::Base
  include MissionBased
  
  has_many(:forms, :inverse_of => :type)
  
  before_destroy(:check_assoc)
  
  validates(:name, :presence => :true, :length => {:maximum => 16})
  validate(:name_unique_per_mission)
  
  default_scope(order("name"))
  
  # creates and returns a default set of form types for the given mission
  # don't need to translate b/c default mission language is English
  def self.create_default(mission)
    ["Short Term", "Long Term", "Security"].collect{|n| create(:name => n, :mission => mission)}
  end
  
  private
    def check_assoc
      raise DeletionError.new(:cant_delete_if_has_forms) unless forms.empty?
    end
    
    def name_unique_per_mission
      errors.add(:name, :must_be_unique) unless unique_in_mission?(:name)
    end
end
