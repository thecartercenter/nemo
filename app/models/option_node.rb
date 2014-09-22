class OptionNode < ActiveRecord::Base
  include MissionBased, FormVersionable, Replicable, Standardizable

  attr_accessible :ancestry, :option_id, :option_set, :option_set_id, :rank, :option, :option_attribs,
    :children_attribs, :is_standard, :standard, :mission_id, :mission, :standard_id, :parent

  belongs_to :option_set
  belongs_to :option, autosave: true
  has_ancestry cache_depth: true

  before_destroy :ensure_no_answers_or_choices
  after_save :update_children

  attr_accessor :children_attribs
  attr_reader :option_attribs
  alias_method :c, :children

  # This attribute is set ONLY after an update using children_attribs.
  # It is true only if the node or any of its descendants have existing children
  # and the update causes their ranks to change.
  attr_accessor :ranks_changed, :options_added, :options_removed
  alias_method :ranks_changed?, :ranks_changed
  alias_method :options_added?, :options_added
  alias_method :options_removed?, :options_removed

  replicable parent_assoc: :option_set, replicate_tree: true, child_assocs: :option, dont_copy: :ancestry

  # Overriding this to avoid error from ancestry.
  alias_method :_children, :children
  def children
    new_record? ? [] : _children
  end

  def has_grandchildren?
    descendants(at_depth: 2).any?
  end

  def all_options
    Option.where(id: descendants.map(&:option_id))
  end

  # Returns options of children, ordered by rank.
  def child_options
    @child_options ||= sorted_children.includes(:option).map(&:option)
  end

  # Returns the child options of the node defined by path of option ids.
  # If node at end of path is leaf node, returns [].
  def options_for_node(path)
    x = find_descendant_by_option_path(path)
    find_descendant_by_option_path(path).try(:child_options) || []
  end

  # Traces the given path of option ids down the tree, returning the OptionNode at the end.
  # Assumes path is an array of Option IDs with 0 or more elements.
  # Returns self if path is empty.
  # Returns nil if any point in path does not find a match.
  # Returns nil if path contains any nils.
  def find_descendant_by_option_path(path)
    return self if path.empty?
    return nil if path.any?(&:nil?)
    return nil unless match = child_with_option_id(path[0])
    match.find_descendant_by_option_path(path[1..-1])
  end

  def child_with_option_id(oid)
    children.detect{ |c| c.option_id == oid }
  end

  # The total number of descendant options.
  def total_options
    descendants.count
  end

  def option_attribs=(attribs)
    attribs.symbolize_keys! if attribs.respond_to?(:symbolize_keys!)
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

  def sorted_children
    children.order('rank')
  end

  def options_by_id
    @options_by_id ||= Option.where(id: descendants.map(&:option_id)).includes(:option_sets, :answers, :choices).index_by(&:id)
  end

  # Given a path (array) of options, returns the ranks of those options at each step of the path.
  # Raises ArgumentError if path not found
  def option_path_to_rank_path(options)
    if options.empty?
      []
    else
      child = child_with_option_id(options.first.id)
      raise ArgumentError.new("Could not find child of node #{id} with option ID #{options.first.id}") if child.nil?
      [child.rank] + child.option_path_to_rank_path(options[1..-1])
    end
  end

  # Given a path (array) of option ranks, returns the options at each step of the path.
  # Raises ArgumentError if path not found.
  def rank_path_to_option_path(ranks)
    if ranks.empty?
      []
    else
      child = children.where(rank: ranks.first).first
      raise ArgumentError.new("Could not find child of node #{id} with rank #{ranks.first}") if child.nil?
      [child.option] + child.rank_path_to_option_path(ranks[1..-1])
    end
  end


  # Serializes all descendants. Meant to be called on root.
  def as_json(options = {})
    arrange_as_json
  end

  def arrange_as_json(hash = nil)
    hash ||= descendants.arrange(order: 'rank')
    hash.map do |node, children|
      {}.tap do |branch|
        %w(id rank).each{ |k| branch[k.to_sym] = node[k] }
        branch[:removable?] = !option_set.option_has_answers?(node['option_id'])
        branch[:option] = options_by_id[node['option_id']].as_json(for_option_set_form: true)
        branch[:children] = arrange_as_json(children) unless children.empty?
      end
    end
  end

  def removable?
    !has_answers?
  end

  def to_s
    "Option Node: ID #{id}  Option ID: " +
    (is_root? ? '[ROOT]' : option_id || '[No option]').to_s +
    " Option: #{option.try(:name)}"
    "  System ID: #{object_id}"
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

      "\n" + sorted_children.map{ |c| c.to_s_indented(:space => options[:space] + 2) }.join
  end

  private

    # Special method for creating/updating a tree of nodes via the children_attribs hash.
    # Sets ranks_changed? flag if the ranks of any of the descendants' children change.
    def update_children
      return if children_attribs.nil?

      reload # Ancestry doesn't seem to work properly without this.

      # Symbolize keys if regular Hash. (not needed for HashWithIndifferentAccess)
      children_attribs.each{ |a| a.symbolize_keys! if a.respond_to?(:symbolize_keys!) }

      self.ranks_changed = false # Assume false to begin.
      self.options_added = false
      self.options_removed = false

      # Index all children by ID for better performance
      children_by_id = children.index_by(&:id)

      # Loop over all children attributes.
      # We use the ! variant of update and create below so that validation
      # errors on children and options will cascade up.
      (children_attribs || []).each_with_index do |attribs, i|

        # If there is a matching (by id) existing child.
        attribs[:id] = attribs[:id].to_i if attribs.key?(:id)
        if attribs[:id] && matching = children_by_id[attribs[:id]]
          self.ranks_changed = true if matching.rank != i + 1
          matching.update_attributes!(attribs.merge(rank: i + 1))
          copy_flags_from_subnode(matching)

          # Remove from hash so that we'll know later which ones weren't updated.
          children_by_id.delete(attribs[:id])
        else
          attribs = copy_denormalized_attribs_to_attrib_hash(attribs)
          self.options_added = true

          # We need to strip ID in case it's present due to a node changing parents.
          children.create!(attribs.except(:id).merge(rank: i + 1))
        end
      end

      # Destroy existing children that were not mentioned in the update.
      self.options_removed = true unless children_by_id.empty?
      children_by_id.values.each{ |c| c.destroy_with_copies }

      # Don't need this anymore. Nullify to prevent duplication on future saves.
      self.children_attribs = nil
    end

    def copy_flags_from_subnode(node)
      self.ranks_changed = true if node.ranks_changed?
      self.options_added = true if node.options_added?
      self.options_removed = true if node.options_removed?
    end

    # Copies denormalized attributes like mission, option_set, etc., to:
    # 1. The given hash.
    # 2. The given hash's subhash at key :option_attribs, if present.
    # Returns the modified hash.
    def copy_denormalized_attribs_to_attrib_hash(hash)
      %w(mission_id option_set_id is_standard standard_id).each{ |k| hash[k.to_sym] = send(k) }
      if hash[:option_attribs]
        %w(mission_id is_standard standard_id).each{ |k| hash[:option_attribs][k.to_sym] = send(k) }
      end
      hash
    end

    def has_answers?
      !is_root? && Answer.any_for_option?(option_id)
    end

    def ensure_no_answers_or_choices
      raise DeletionError.new(:cant_delete_if_has_response) if has_answers?
    end
end
