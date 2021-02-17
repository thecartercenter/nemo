# frozen_string_literal: true

# common methods for classes that are related to a mission
module MissionBased
  extend ActiveSupport::Concern

  included do
    # Only Setting has a has_one association, so don't pluralize
    inverse = (model_name == "Setting" ? model_name.to_s : model_name.plural).downcase.to_sym
    belongs_to :mission, inverse_of: inverse

    scope :for_mission, ->(m) { where(mission: m) }
  end

  class_methods do
    def mission_based?
      true
    end

    # DEPRECATED: This should go away and be replaced with use of destroy and a background job.
    # No need to maintain all this extra logic. Mission delete happens rarely and can be slow.
    # when a mission is deleted, pre-remove all records related to a mission
    def mission_pre_delete(mission)
      scope = where(mission_id: mission)
      terminate_sub_relationships(scope.pluck(:id)) if respond_to?(:terminate_sub_relationships)
      scope.delete_all
    end
  end

  # checks if this object is unique in the mission according to the attrib given by attrib_name
  def unique_in_mission?(attrib_name)
    rel = self.class.for_mission(mission).where(attrib_name => send(attrib_name))
    rel = rel.where.not(id: id) unless new_record?
    rel.count.zero?
  end

  def mission_config
    Setting.for_mission(mission)
  end
end
