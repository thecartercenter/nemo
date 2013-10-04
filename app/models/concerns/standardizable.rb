module Standardizable
  extend ActiveSupport::Concern

  included do
    # create a flag to use with the callback below
    attr_accessor :changing_in_replication

    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name, :inverse_of => :copies)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id', :inverse_of => :standard)

    # create hooks to copy is_standard param to children
    # this doesn't work with before_create for some reason
    before_save(:copy_is_standard_from_parent)
    before_save(:copy_is_standard_to_children)

    # create hooks to replicate changes to copies for key classes
    after_save(:replicate_save_to_copies)

    # we make this one before destroy because if we do it after then we violate an fk constraint before we get the chance
    before_destroy(:replicate_destruction_to_copies)

    # returns a scope for all standard objects of that are importable to the given mission
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
    def replicate_changes_to_copies(change_type)
      Rails.logger.debug("********** replicating changes to copies (type: #{change_type})")
      if changing_in_replication
        changing_in_replication = false
      else
        if change_type == :destroy
          copies.each{|c| replicate_destruction(c.mission)}
        else
          # if we just run replicate for each copy's mission, all changes will be propagated
          copies.each{|c| replicate(c.mission)} if %w(Form Question Questioning OptionSet Option).include?(self.class.name)
        end
      end
    end

    def replicate_save_to_copies
      replicate_changes_to_copies(:save)
    end
    
    def replicate_destruction_to_copies
      replicate_changes_to_copies(:destroy)
    end

    def copy_is_standard_to_children
      Rails.logger.debug("********** copying is_standard to children")
      self.class.replication_options[:assocs].each do |assoc|
        refl = self.class.reflect_on_association(assoc)
        if refl.collection?
          send(assoc).each do |o| 
            o.is_standard = is_standard?
            o.mission = nil if is_standard?
          end
        else
          if send(assoc)
            send(assoc).is_standard = is_standard? 
            send(assoc).mission = nil if is_standard?
          end
        end
      end
    end

    def copy_is_standard_from_parent
      Rails.logger.debug("********** copying is_standard from parent")
      # if a parent is defined and there is a matching association 
      # (e.g. questioning has parent = form, and a form association exists)
      if (parent_assoc = self.class.replication_options[:parent]) && self.respond_to?(parent_assoc)
        self.is_standard = self.send(parent_assoc).is_standard?
        self.mission = nil if is_standard?
      end
    end
end