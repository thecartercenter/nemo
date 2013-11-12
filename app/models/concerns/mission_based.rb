# common methods for classes that are related to a mission
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

      # only Setting has a has_one association, so don't pluralize
      inverse = (base.model_name == "Setting" ? base.model_name : base.model_name.plural).downcase.to_sym
      belongs_to(:mission, :inverse_of => inverse)

      # scope to find objects with the given mission
      # mission can be nil
      scope(:for_mission, lambda{|m| where(:mission_id => m.try(:id))})
    end

    # checks if this object is unique in the mission according to the attrib given by attrib_name
    def unique_in_mission?(attrib_name)
      rel = self.class.for_mission(mission).where(attrib_name => send(attrib_name))
      rel = rel.where("id != ?", id) unless new_record?
      rel.count == 0
    end
  end
end
