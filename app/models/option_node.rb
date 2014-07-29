class OptionNode < ActiveRecord::Base
  include MissionBased, Replicable, Standardizable

  attr_accessible :ancestry, :option_id, :option_set, :option_set_id, :rank, :option, :option_attribs,
    :children_attribs, :is_standard, :standard, :mission_id, :standard_id

  belongs_to :option_set
  belongs_to :option, :autosave => true
  has_ancestry

  after_save :update_children

  attr_accessor :children_attribs
  attr_reader :option_attribs
  alias_method :c, :children

  # This attribute is set ONLY after an update using children_attribs.
  # It is true only if the node or any of its descendants have existing children
  # and the update causes their ranks to change.
  attr_accessor :ranks_changed
  alias_method :ranks_changed?, :ranks_changed

  replicable :parent_assoc => :option_set, :replicate_tree => true, :child_assocs => :option, :dont_copy => :ancestry

  # Copy the mission ID from the option set.
  def option_set=(set)
    association(:option_set).writer(set)
    self.mission = set.try(:mission)
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
    is_root? ? nil : option_set.try(:level, depth)
  end

  def to_s
    "Option Node: ID #{id}  Option ID: " + (is_root? ? '[ROOT]' : option_id || '[No option]').to_s + "  System ID: #{object_id}"
  end

  # returns a string representation of this node and its children, indented by the given amount
  # options[:space] - the number of spaces to indent
  def to_s_indented(options = {})
    options[:space] ||= 0

    # indentation
    (' ' * options[:space]) +

      # option level name, option name
      ["(#{level.try(:name)})", "#{rank}. #{option.try(:name) || '[Root]'}"].compact.join(' ') +

      # parent, mission
      " (mission: #{mission.try(:name) || '[None]'}, " +
        "option-mission: #{option ? option.mission.try(:name) || '[None]' : '[N/A]'}, " +
        "option-set: #{option_set.try(:name) || '[None]'})" +

      "\n" + children.order('rank').map{ |c| c.to_s_indented(:space => options[:space] + 2) }.join
  end

  private

    # Special method for creating/updating a tree of nodes via the children_attribs hash.
    # Sets ranks_changed? flag if the ranks of any of the descendants' children change.
    def update_children
      return if children_attribs.nil?

      reload # Ancestry doesn't seem to work properly without this.
      children_attribs.each(&:symbolize_keys!) if children_attribs
      copy_attribs_to_children

      self.ranks_changed = false # Assume false to begin.

      # Index all children by ID for better performance
      children_by_id = children.index_by(&:id)

      # Loop over all children attributes.
      (children_attribs || []).each_with_index do |attribs, i|
        if attribs[:id]
          if matching = children_by_id[attribs[:id]]
            self.ranks_changed = true if matching.rank != i + 1
            matching.update_attributes!(attribs.merge(rank: i + 1))
            self.ranks_changed = true if matching.ranks_changed?

            # Remove from hash so that we'll know later which ones weren't updated.
            children_by_id.delete(attribs[:id])
          end
        else
          children.create!(attribs.merge(rank: i + 1))
        end
      end

      # Destroy existing children that were not mentioned in the update.
      children_by_id.values.each{ |c| c.destroy_with_copies }
    end

    def copy_attribs_to_children
      (children_attribs || []).each do |attribs|
        [:mission_id, :option_set_id, :is_standard, :standard_id].each{ |k| attribs[k] = send(k) }
        [:mission_id, :is_standard, :standard_id].each{ |k| attribs[:option_attribs].try('[]=', k, send(k)) }
      end
    end
end
