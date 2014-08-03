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

  # Returns options of children, ordered by rank.
  def child_options
    sorted_children.map(&:option)
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

  def options_by_id
    @options_by_id ||= Option.where(id: descendants.map(&:option_id)).includes(:option_sets, :answers, :choices).index_by(&:id)
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

      copy_attribs_to_children

      self.ranks_changed = false # Assume false to begin.
      self.options_added = false
      self.options_removed = false

      # Index all children by ID for better performance
      children_by_id = children.index_by(&:id)

      # Loop over all children attributes.
      # We use the ! variant of update and create below so that validation
      # errors on children and options will cascade up.
      (children_attribs || []).each_with_index do |attribs, i|
        attribs[:id] = attribs[:id].to_i if attribs.key?(:id)
        if attribs[:id] && matching = children_by_id[attribs[:id]]
          self.ranks_changed = true if matching.rank != i + 1
          matching.update_attributes!(attribs.merge(rank: i + 1))
          copy_flags_from_subnode(matching)

          # Remove from hash so that we'll know later which ones weren't updated.
          children_by_id.delete(attribs[:id])
        else
          self.options_added = true
          children.create!(attribs.except(:id).merge(rank: i + 1))
        end
      end

      # Destroy existing children that were not mentioned in the update.
      self.options_removed = true unless children_by_id.empty?
      children_by_id.values.each{ |c| c.destroy_with_copies }
    end

    def copy_flags_from_subnode(node)
      self.ranks_changed = true if node.ranks_changed?
      self.options_added = true if node.options_added?
      self.options_removed = true if node.options_removed?
    end

    def copy_attribs_to_children
      (children_attribs || []).each do |attribs|
        [:mission_id, :option_set_id, :is_standard, :standard_id].each{ |k| attribs[k] = send(k) }
        [:mission_id, :is_standard, :standard_id].each{ |k| attribs[:option_attribs].try('[]=', k, send(k)) }
      end
    end

    def has_answers?
      !is_root? && Answer.any_for_option?(option_id)
    end

    def ensure_no_answers_or_choices
      raise DeletionError.new(:cant_delete_if_has_response) if has_answers?
    end

    def sorted_children
      children.order('rank')
    end
end
