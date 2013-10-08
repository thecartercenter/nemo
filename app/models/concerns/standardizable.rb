module Standardizable
  extend ActiveSupport::Concern

  # we assume that any Standardizable class also imports Replicable

  # list of class names whose changes should be replicated on save
  CLASSES_TO_REPLICATE_ON_SAVE = %w(Form Question Questioning OptionSet Option)

  included do
    # create a flag to use with the callback below
    attr_accessor :changing_in_replication

    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name, :inverse_of => :copies)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id', :inverse_of => :standard)

    # create hooks to copy key params from parent and to children
    # this doesn't work with before_create for some reason
    before_save(:copy_is_standard_and_mission_from_parent)
    before_save(:copy_is_standard_and_mission_to_children)

    # create hooks to replicate changes to copies for key classes
    after_save(:replicate_save_to_copies)

    # we make this one before destroy because if we do it after then we violate an fk constraint before we get the chance
    before_destroy(:replicate_destruction_to_copies)

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
    !standard.nil?
  end

  # returns number of copies, or zero if this obj is not standard
  # uses eager loaded field if available
  def copy_count
    is_standard? ? (respond_to?(:copy_count_col) ? copy_count_col : copies.count) : 0
  end

  private
    def replicate_save_to_copies
      replicate_changes_to_copies(:save)

      return true
    end
    
    def replicate_destruction_to_copies
      replicate_changes_to_copies(:destroy)

      return true
    end

    def replicate_changes_to_copies(change_type)
      # don't replicate changes arising from the replication process itself, as this leads to an infinite loop
      if changing_in_replication
        changing_in_replication = false
      else
        if change_type == :destroy
          copies.each{|c| replicate_destruction(c.mission)}
        else
          # we only need to replicate save on certain classes
          # can't really remember why :(
          if CLASSES_TO_REPLICATE_ON_SAVE.include?(self.class.name)
            # if we just run replicate for each copy's mission, all changes will be propagated
            copies.each{|c| replicate(c.mission)}
          end
        end
      end

      return true
    end

    # copies the is_standard and mission properties from any parent association
    def copy_is_standard_and_mission_from_parent
      # reflect on parent association, if it exists
      parent_assoc = self.class.reflect_on_association(self.class.replication_options[:parent])

      # if the parent association exists and is a belongs_to association 
      # (e.g. questioning has parent = form, and a form association exists)
      if parent_assoc.try(:macro) == :belongs_to
        # copy the params
        self.is_standard = self.send(parent_assoc.name).is_standard?
        self.mission = self.send(parent_assoc.name).mission
      end

      return true
    end    

    # copies the is_standard and mission properties to any children associations
    def copy_is_standard_and_mission_to_children
      # iterate over children assocs
      self.class.replication_options[:assocs].each do |assoc|
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