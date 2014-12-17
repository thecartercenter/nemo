# Holds behaviors related to standard objects including importing, etc.
# All Standardizable objects are assumed to be Replicable also.
module Standardizable
  extend ActiveSupport::Concern

  included do
    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name, :inverse_of => :copies)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id', :inverse_of => :standard)

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

  # get copy in the given mission, if it exists (there can only be one)
  def copy_for_mission(mission)
    copies.for_mission(mission).first
  end

  # adds an obj to the list of copies
  def add_copy(obj)
    # don't add if already there
    copies << obj unless copies.include?(obj)
  end

  # returns number of copies
  # uses eager loaded field if available
  def copy_count
    respond_to?(:copy_count_col) ? copy_count_col : copies.count
  end
end
