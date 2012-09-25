module MissionBased
  module ClassMethods
    def mission_based?
      return true
    end
  end

  def self.included(base)
    # ruby idiom to activate class methods
    base.extend(ClassMethods)
    
    # add scope
    base.class_eval do
      belongs_to(:mission, :inverse_of => base.model_name.plural.to_sym)
      scope(:for_mission, lambda{|m| m.nil? ? where("0") : where(:mission_id => m.id)})
    end
  end
end