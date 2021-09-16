# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: option_nodes
#
#  id             :uuid             not null, primary key
#  ancestry       :text
#  ancestry_depth :integer          default(0), not null
#  rank           :integer          default(1), not null
#  sequence       :integer          default(0), not null
#  standard_copy  :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  mission_id     :uuid
#  old_id         :integer
#  option_id      :uuid
#  option_set_id  :uuid             not null
#  original_id    :uuid
#
# Indexes
#
#  index_option_nodes_on_ancestry       (ancestry)
#  index_option_nodes_on_mission_id     (mission_id)
#  index_option_nodes_on_option_id      (option_id)
#  index_option_nodes_on_option_set_id  (option_set_id)
#  index_option_nodes_on_original_id    (original_id)
#  index_option_nodes_on_rank           (rank)
#
# Foreign Keys
#
#  option_nodes_mission_id_fkey     (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  option_nodes_option_id_fkey      (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#  option_nodes_option_set_id_fkey  (option_set_id => option_sets.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# OptionNodes belong to OptionSet, and also to their parents (they're a tree).
# Rank represents the order of the options for a set
# Sequence is for printing out for SMS?
#
# See also the documentation at docs/architecture.md.
class OptionNode < ApplicationRecord
  include Replication::Replicable
  include MissionBased

  # Needs to be standardizable (with original_id) so we can find OptionNodes to link conditions to.
  include Replication::Standardizable

  # Number of descendants that make a 'huge' node.
  HUGE_CUTOFF = 100

  # Number of nodes to return as JSON if node is 'huge'.
  TO_SERIALIZE_IF_HUGE = 10

  belongs_to :option_set
  belongs_to :option, autosave: true
  has_many :conditions, inverse_of: :option_node, dependent: :restrict_with_exception
  has_many :answers, dependent: :restrict_with_exception
  has_many :choices, dependent: :restrict_with_exception
  has_ancestry cache_depth: true, primary_key_format: Ancestry::ANCESTRY_PATTERN

  before_validation { self.ancestry = nil if ancestry.blank? }
  after_update :update_answer_search_vectors
  after_save :update_children

  attr_accessor :children_attribs
  attr_reader :option_attribs

  # This attribute is set ONLY after an update using children_attribs.
  # It is true only if the node or any of its descendants have existing children
  # and the update causes their ranks to change.
  attr_accessor :ranks_changed, :options_added, :options_removed
  attr_writer :child_options

  alias ranks_changed? ranks_changed
  alias options_added? options_added
  alias options_removed? options_removed

  scope :by_canonical_name, ->(name) { joins(:option).where("LOWER(canonical_name) = ?", name.downcase) }

  replicable child_assocs: %i[children option], backward_assocs: :option_set,
             # If the source of the clone is an option set, we need to replicate all nodes.
             # Otherwise they are reusable just like the OptionSet itself.
             dont_reuse: ->(replicator) { replicator.source.is_a?(OptionSet) }

  clone_options follow: %i[option]

  delegate :shortcode_length, to: :option_set
  delegate :name, to: :level, prefix: true, allow_nil: true
  delegate :name, :name_translations, :canonical_name, :coordinates?, :latitude, :longitude, to: :option

  # Given a set of nodes, preloads child_options for all in constant number of queries.
  def self.preload_child_options(roots)
    ancestries = roots.map { |r| "'#{r.id}'" }.join(",")
    nodes_by_root_id = OptionNode.includes(:option)
      .where("ancestry IN (#{ancestries})")
      .order("rank")
      .group_by(&:ancestry)
    roots.each { |r| r.child_options = (nodes_by_root_id[r.id] || []).map(&:option) }
  end

  def sorted_children
    children.order(:rank).includes(:option)
  end
  alias c sorted_children

  def all_options
    Option.where(id: descendants.map(&:option_id))
  end

  def max_depth
    @max_depth ||= descendants.maximum("ancestry_depth")
  end

  # Returns options of children, ordered by rank.
  def child_options
    @child_options ||= sorted_children.map(&:option)
  end

  # The total number of descendant options.
  def total_options
    @total_options ||= descendants.count
  end

  # Fetches the first count nodes in the tree using preorder traversal.
  def first_n_descendants(count)
    nodes = []
    sorted_children.each do |c|
      nodes << c
      nodes += c.first_n_descendants(count - nodes.size)
      break if nodes.size >= count
    end
    nodes[0...count]
  end

  def option_attribs=(attribs)
    attribs = attribs.to_h
    attribs.symbolize_keys! if attribs.respond_to?(:symbolize_keys!)
    attribs[:mission_id] = mission_id
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

  def huge?
    total_options > HUGE_CUTOFF
  end

  def preordered_descendants
    self.class.sort_by_ancestry(descendants.order(:rank)) { |a, b| a.rank <=> b.rank }
  end

  def first_leaf_option_node
    (sc = sorted_children).any? ? sc.first : self
  end

  # an odk-friendly unique code
  def odk_code
    ODK::CodeMapper.instance.code_for_item(self)
  end

  # an odk-friendly unique code for this node's parent
  def parent_odk_code
    ODK::CodeMapper.instance.code_for_item(parent)
  end

  # Serializes all descendants. Meant to be called on root.
  def as_json(_ = {})
    arrange_as_json
  end

  # Arranges descendant nodes in a nested hash structure.
  # If options[:truncate_if_huge] is true, returns on the first TO_SERIALIZE_IF_HUGE nodes.
  # Also forwards options[:eager_load_option_assocs] to options_by_id.
  def arrange_with_options(options = {})
    # If node has huge number of children just return the first 10.
    nodes = if huge? && options[:truncate_if_huge]
              first_n_descendants(TO_SERIALIZE_IF_HUGE)
            else
              descendants.ordered_by_ancestry_and("rank")
            end

    opt_hash = Option.where(id: nodes.map(&:option_id)).index_by(&:id)
    nodes.each { |n| n.option = opt_hash[n.option_id] }

    # arrange_nodes is an Ancestry gem function that takes a set of nodes
    # and arranges them in the hash structure.
    self.class.arrange_nodes(nodes)
  end

  def arrange_as_json(hash = nil)
    # If this is the first call, hash will be nil.
    # We fetch and arrange the nodes this first time, and then pass chunks of the fetch node hierarchy
    # in subsequent recursive calls.
    hash = arrange_with_options(truncate_if_huge: true, eager_load_option_assocs: true) if hash.nil?

    hash.map do |node, children|
      {}.tap do |branch|
        %w[id rank].each { |k| branch[k.to_sym] = node[k] }
        branch[:option] = node.option.as_json(
          only: %i[id latitude longitude name_translations value], methods: %i[name]
        )

        # We've temporarily removed the check for whether this node has associated answers because it
        # is too expensive to check for option sets with lots of questions and answers
        # (e.g. the 'Yes/No' set). Once we change answers to point directly to option_nodes, this will
        # be much cheaper to check given that we can use indices.
        # Until then, if someone tries to delete a node that has answers, the restrict_with_exception
        # checks on the associations should catch it and display an error.
        # This could still cause crashes of the type that motivated
        # this fix, but they should be much rarer because folks likely won't be trying to delete an option
        # that has so many answers.
        branch[:removable] = true

        # Recursive step.
        branch[:children] = arrange_as_json(children) unless children.empty?
      end
    end
  end

  # arranges option descendant nodes into rows for export.
  # rows are created for leaf nodes only and contain the node id and the
  # localized option names in the mission preferred locale.
  def arrange_as_rows(hash = nil, parent_path = [])
    hash = arrange_with_options if hash.nil?

    hash.each_with_object([]) do |(node, children), rows|
      path = parent_path + [node.option]

      # output a row if we've hit a leaf node or a parent node with coordinates
      if children.empty? || (option_set.allow_coordinates? && node.option.coordinates?)
        # use the option path to construct the list of cell values
        values = *preferred_name_translations(path)

        # add padding for missing values
        num_values = option_set.multilevel? ? option_set.levels.size : 1
        padding = [num_values - values.length, 0].max
        values = values.concat([nil] * padding)

        row = [node.id, *values]

        # add the coordinates if the option set allows coordinates
        row << node.option.coordinates if option_set.allow_coordinates?

        # add the node's shortcode
        row << node.shortcode

        rows << row
      end

      # recursively collect rows for the children
      rows.concat(arrange_as_rows(children, path)) if children.present?
    end
  end

  def preferred_name_translations(path)
    path.map do |p|
      translations = mission_config.preferred_locales.map { |locale| p.name(locale.to_s) }
      translations.compact.first
    end
  end

  # Path to this node without the root.
  def path
    ancestors[1..] << self
  end

  # Returns the total number of options omitted from the JSON serialization.
  def options_not_serialized
    total_options - (huge? ? TO_SERIALIZE_IF_HUGE : 0)
  end

  def to_s
    "Option Node: ID #{id}  Option ID: " +
      (is_root? ? "[ROOT]" : option_id || "[No option]").to_s +
      " Option: #{option.try(:name)}" \
      "  System ID: #{object_id}"
  end

  # returns a string representation of this node and its children, indented by the given amount
  # options[:space] - the number of spaces to indent
  def to_s_indented(options = {})
    options[:space] ||= 0

    # indentation
    +(" " * options[:space]) <<

      # option level name, option name
      ["(#{level.try(:name)})", "#{rank}. #{option.try(:name) || '[Root]'} [#{id}]"].compact.join(" ") <<

      # parent, mission
      " (mission: #{mission.try(:name) || '[None]'}, " \
      "option-mission: #{option ? option.mission.try(:name) || '[None]' : '[N/A]'}, " \
      "option-set: #{option_set.try(:name) || '[None]'} " \
      "sequence: #{try(:sequence) || '[None]'})" \
      "\n" << sorted_children.map { |c| c.to_s_indented(space: options[:space] + 2) }.join
  end

  def shortcode
    @shortcode = Base36.to_padded_base36(sequence, length: shortcode_length)
  end

  def max_sequence
    # For some reason ancestry scopes requests through the current node even if you don't
    # call `where` through `self`, so you need to explicitly call unscoped here.
    # Also need to explicitly ignore deleted records because using unscoped.
    self.class.unscoped.where(option_set_id: option_set_id).maximum(:sequence) || 0
  end

  # Whether this node appears in any Answers or Choices.
  # We delegate this to an external object for performance reasons.
  def data?
    answers.any? || choices.any?
  end

  # Whether this node is used in any Forms.
  # We delegate this to an external object for performance reasons.
  def in_use?
    conditions.any?
  end

  protected

  # Special method for creating/updating a tree of nodes via the children_attribs hash.
  # Sets ranks_changed? flag if the ranks of any of the descendants' children change.
  def update_children
    # It's important not to run through this method if children_attribs is nil, since otherwise
    # children will get deleted on a partial update.
    return if children_attribs.nil?

    self.children_attribs = [] if children_attribs == "NONE"

    reload # Ancestry doesn't seem to work properly without this.

    # Symbolize keys if regular Hash. (not needed for HashWithIndifferentAccess)
    children_attribs.each { |a| a.symbolize_keys! if a.respond_to?(:symbolize_keys!) }

    self.ranks_changed = false # Assume false to begin.
    self.options_added = false
    self.options_removed = false

    # Index all children by ID for better performance
    # Note: "scoping" deprecation warnings are waiting on https://github.com/stefankroes/ancestry/issues/485.
    children_by_id = children.index_by(&:id)

    # Loop over all children attributes.
    # We use the ! variant of update and create below so that validation
    # errors on children and options will cascade up.
    (children_attribs || []).each_with_index do |attribs, i|
      attribs = attribs.last if attribs.is_a?(Array)

      # If there is a matching (by id) existing child.
      if attribs[:id] && (matching = children_by_id[attribs[:id]])
        self.ranks_changed = true if matching.rank != i + 1

        # Not sure why this is needed, temporary hack.
        attribs[:children_attribs] = "NONE" if attribs[:children_attribs].nil?

        matching.update!(attribs.merge(rank: i + 1))
        copy_flags_from_subnode(matching)

        # Remove from hash so that we'll know later which ones weren't updated.
        children_by_id.delete(attribs[:id])
      else
        attribs = copy_denormalized_attribs_to_attrib_hash(attribs)
        self.options_added = true

        # We need to strip ID in case it's present due to a node changing parents.
        # Note: "scoping" deprecation warnings are waiting on https://github.com/stefankroes/ancestry/issues/485.
        children.create!(attribs.except(:id).merge(rank: i + 1).merge(sequence: max_sequence + 1))
      end
    end

    # Destroy existing children that were not mentioned in the update.
    self.options_removed = true unless children_by_id.empty?
    children_by_id.values.each(&:destroy)

    # Don't need this anymore. Nullify to prevent duplication on future saves.
    self.children_attribs = nil
  end

  private

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
    %w[mission_id option_set_id standard_copy].each { |k| hash[k.to_sym] = send(k) }
    %w[mission_id].each { |k| hash[:option_attribs][k.to_sym] = send(k) } if hash[:option_attribs]
    hash
  end

  def update_answer_search_vectors
    return unless option&.saved_change_to_name_translations?
    Results::AnswerSearchVectorUpdater.instance.update_for_option_node(self)
  end
end
