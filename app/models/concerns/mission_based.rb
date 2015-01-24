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
      scope(:for_mission_id, lambda{|m| where(:mission_id => m)})

      # when a mission is deleted, pre-remove all records related to a mission
      def self.mission_pre_delete(mission)
        mission_related = self.where(mission_id:mission)

        if self.respond_to?(:terminate_sub_relationships)
          self.terminate_sub_relationships(mission_related.pluck(:id))
        end

        mission_related.delete_all
      end

    end

    # checks if this object is unique in the mission according to the attrib given by attrib_name
    def unique_in_mission?(attrib_name)
      rel = self.class.for_mission(mission).where(attrib_name => send(attrib_name))
      rel = rel.where("id != ?", id) unless new_record?
      rel.count == 0
    end

  end
end
