# Holds behaviors related to standard objects including importing, etc.
# All Standardizable objects are assumed to be Replicable also.
module Standardizable
  extend ActiveSupport::Concern

  included do
    # returns a scope for all standard objects of the current class that are importable to the given mission
    # (i.e. that don't already exist in that mission)
    def self.importable_to(mission)
      # get ids of all standard objs already copied to the mission
      existing_ids = for_mission(mission).where('standard_id IS NOT NULL').map(&:standard_id)

      # build relation
      rel = where(:is_standard => true)
      rel = rel.where("id NOT IN (?)", existing_ids) unless existing_ids.empty?
      rel
    end
  end

  # returns whether the object is standard or related to a standard object
  def standardized?
    is_standard? || standard_copy?
  end

  def standard_copy?
    standard_id.present?
  end
end
