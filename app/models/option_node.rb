class OptionNode < ActiveRecord::Base
  include MissionBased

  attr_accessible :ancestry, :option_id, :option_set, :option_set_id, :rank, :option, :option_attribs, :children_attribs

  belongs_to :option_set
  belongs_to :option, :autosave => true
  has_ancestry

  before_validation :copy_mission_to_option
  after_save :update_children

  attr_accessor :children_attribs
  attr_reader :option_attribs
  alias_method :c, :children

  # This attribute is set ONLY after an update using children_attribs.
  # It is true only if the node or any of its descendants have existing children
  # and the update causes their ranks to change.
  attr_accessor :ranks_changed
  alias_method :ranks_changed?, :ranks_changed

  # Copy the mission ID from the option set.
  def option_set=(set)
    association(:option_set).writer(set)
    self.mission = set.mission
  end

  def option_attribs=(attribs)
    attribs.symbolize_keys!
    if attribs[:id]
      self.option = Option.find(attribs[:id])
      option.assign_attributes(attribs)
    else
      build_option(attribs)
    end
  end

  # Gets the OptionLevel for this node.
  def level
    is_root? ? nil : option_set.level(depth)
  end

  private

    # Special method for creating/updating a tree of nodes via the children_attribs hash.
    # Sets ranks_changed? flag if the ranks of any of the descendants' children change.
    def update_children
      reload # Ancestry doesn't seem to work properly without this.
      copy_mission_to_children_attribs # Need this or we get a validation error.

      self.ranks_changed = false # Assume false to begin.

      # Index all children by ID for better performance
      children_by_id = children.index_by(&:id)

      # Loop over all children attributes.
      (children_attribs || []).each_with_index do |attribs, i|
        attribs.symbolize_keys!

        if attribs[:id]
          if matching = children_by_id[attribs[:id]]
            self.ranks_changed = true if matching.rank != i + 1
            matching.update_attributes!(attribs.merge(rank: i + 1))
            self.ranks_changed = true if matching.ranks_changed?

            # Remove from hash so that we'll know later which ones weren't updated.
            children_by_id.delete(attribs[:id])
          end
        else
          children.create!(attribs.merge(option_set: option_set, rank: i + 1))
        end
      end

      # Destroy existing children that were not mentioned in the update.
      children_by_id.values.each{ |c| c.destroy }
    end

    def copy_mission_to_option
      option.mission = mission if option && option.mission.nil?
      return true
    end

    def copy_mission_to_children_attribs
      (children_attribs || []).each do |c|
        c[:option_attributes][:mission_id] = mission.id if c[:option_attributes]
        c['option_attributes'][:mission_id] = mission.id if c['option_attributes']
      end
    end
end
