# Holds behaviors related to standard objects including re-replication, importing, etc.
# All Standardizable objects are assumed to be Replicable also.
module Standardizable
  extend ActiveSupport::Concern

  included do
    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name, :inverse_of => :copies)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id', :inverse_of => :standard)

    # create hooks to copy key params from parent and to children
    # this doesn't work with before_create for some reason
    before_validation(:copy_is_standard_and_mission_from_parent)
    before_validation(:copy_is_standard_and_mission_to_children)

    validates(:mission_id, :presence => true, :unless => ->(o) {o.is_standard?})

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

  # get copy in the given mission, if it exists (there can only be one)
  # (we can assume that all standardizable classes are also mission-based)
  def copy_for_mission(mission)
    copies.for_mission(mission).first
  end

  # returns whether the object is standard or related to a standard object
  def standardized?
    is_standard? || standard_copy?
  end

  def standard_copy?
    standard_id.present?
  end

  # adds an obj to the list of copies
  def add_copy(obj)
    # don't add if already there
    copies << obj unless copies.include?(obj)
  end

  # returns number of copies, or zero if this obj is not standard
  # uses eager loaded field if available
  def copy_count
    is_standard? ? (respond_to?(:copy_count_col) ? copy_count_col : copies.count) : 0
  end

  private

    # copies the is_standard and mission properties from any parent association
    def copy_is_standard_and_mission_from_parent
      # reflect on parent association, if it exists
      parent_assoc = self.class.reflect_on_association(self.class.replication_options[:parent_assoc])

      # if the parent association exists and is a belongs_to association and parent exists
      # (e.g. questioning has parent = form, and a form association exists, and parent exists)
      if parent_assoc.try(:macro) == :belongs_to && parent = self.send(parent_assoc.name)
        # copy the params
        self.is_standard = parent.is_standard?
        self.mission = parent.mission
      end
      return true
    end

    # copies the is_standard and mission properties to any children associations
    def copy_is_standard_and_mission_to_children
      # iterate over children assocs
      self.class.replication_options[:child_assocs].each do |assoc|
        refl = self.class.reflect_on_association(assoc)

        # if is a collection association, copy to each, else copy to individual
        if refl.collection?
          send(assoc).each do |o|
            o.is_standard = is_standard?
            o.mission = mission
          end
        else
          unless send(assoc).nil?
            send(assoc).is_standard = is_standard?
            send(assoc).mission = mission
          end
        end
      end
      return true
    end
end
