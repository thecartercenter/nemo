# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: option_sets
#
#  id                   :uuid             not null, primary key
#  allow_coordinates    :boolean          default(FALSE), not null
#  geographic           :boolean          default(FALSE), not null
#  level_names          :jsonb
#  name                 :string(255)      not null
#  sms_guide_formatting :string(255)      default("auto"), not null
#  standard_copy        :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mission_id           :uuid
#  original_id          :uuid
#  root_node_id         :uuid
#
# Indexes
#
#  index_option_sets_on_geographic           (geographic)
#  index_option_sets_on_mission_id           (mission_id)
#  index_option_sets_on_name_and_mission_id  (name,mission_id) UNIQUE
#  index_option_sets_on_original_id          (original_id)
#  index_option_sets_on_root_node_id         (root_node_id) UNIQUE
#
# Foreign Keys
#
#  option_sets_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  option_sets_option_node_id_fkey  (root_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# A collection of Options for a select_one or select_multiple question. May be flat or multi-level.
#
# See also the documentation at docs/architecture.md.
class OptionSet < ApplicationRecord
  before_validation :copy_attribs_to_root_node
  before_validation :normalize_fields

  # This need to be up here or they will run too late.
  before_destroy :check_associations
  before_destroy :nullify_root_node
  # We use this instead of autosave since autosave doesn't work right for belongs_to.
  # It is up here because it should happen early, e.g., before form version callbacks.
  after_save :save_root_node

  include Replication::Replicable
  include Replication::Standardizable
  include MissionBased

  SMS_GUIDE_FORMATTING_OPTIONS = %w[auto inline appendix treat_as_text].freeze

  # We do this instead of using dependent: :destroy because in the latter case
  # the dependent object doesn't know who destroyed it.
  before_destroy { report_option_set_choices.each(&:option_set_destroyed) }

  has_many :questions, inverse_of: :option_set, dependent: :restrict_with_exception
  has_many :questionings, through: :questions
  has_many :option_nodes, -> { order(:rank) }, dependent: :destroy, inverse_of: :option_set
  has_many :report_option_set_choices, class_name: "Report::OptionSetChoice", inverse_of: :option_set,
                                       dependent: :destroy
  belongs_to :root_node, class_name: "OptionNode", dependent: :destroy

  scope :by_name, -> { order("option_sets.name") }
  scope :default_order, -> { by_name }

  validates :name, uniqueness: {scope: :mission_id}

  replicable child_assocs: :root_node, backwards_assocs: :questions,
             uniqueness: {field: :name, style: :sep_words}

  clone_options follow: %i[option_nodes]

  delegate :ranks_changed?, :children, :c, :options_added?, :options_removed?,
    :total_options, :descendants, :all_options, :max_depth, :options_not_serialized, :arrange_as_rows,
    :arrange_with_options, :sorted_children, :first_leaf_option_node,
    to: :root_node

  # These methods are for the form.
  attr_writer :multilevel

  # Indicates that this OptionSet is being created to be added to a question of the given type
  attr_accessor :adding_to_question_type

  # Efficiently deletes option nodes for all option sets with given IDs.
  def self.terminate_sub_relationships(option_set_ids)
    # Must nullify these first to avoid fk error
    OptionSet.where(id: option_set_ids).update_all(root_node_id: nil)
    OptionNode.where("option_set_id IN (?)", option_set_ids).delete_all unless option_set_ids.empty?
  end

  # Avoids N+1 queries for top level options for a set of option sets.
  # Assumes root_node has been eager loaded.
  def self.preload_top_level_options(option_sets)
    return if option_sets.empty?
    OptionNode.preload_child_options(option_sets.map(&:root_node))
  end

  def children_attribs=(attribs)
    build_root_node if root_node.nil?
    root_node.children_attribs = attribs
  end

  def preordered_option_nodes
    root_node.preordered_descendants
  end

  # Given an Option, returns the path down the tree of Options in this set to that Option.
  # Returns nil if option not found in set.
  def path_to_option(option)
    node = OptionNode.find_by(option_set: self, option: option)
    return nil if node.nil?

    # Trim the root node and map to options.
    node.ancestors[1..].map(&:option) + [option]
  end

  # Gets the OptionLevel for the given depth (1-based)
  def level(depth)
    levels&.[](depth - 1)
  end

  # Gets the OptionLevel name for the given depth. Returns nil if level not found.
  def level_name_for_depth(depth)
    level(depth)&.name
  end

  def levels
    return @levels if defined?(@levels)
    return @levels = nil unless multilevel?
    @levels = level_names.map do |n|
      OptionLevel.new(name_translations: n, option_set: self)
    end
  end

  def levels=(levels)
    self.level_names = levels.map(&:name_translations)
  end

  def level_names=(names)
    self[:level_names] = names.is_a?(Hash) ? names.values : names
  end

  def level_count
    level_names&.size || 1
  end

  def multilevel?
    return @multilevel if defined?(@multilevel)
    @multilevel = level_count > 1
  end
  alias multilevel multilevel?

  def huge?
    root_node.present? ? root_node.huge? : false
  end

  def can_be_multilevel?
    !(select_multiple_questions? || huge? || !question_type_supports_multilevel?)
  end

  def question_type_supports_multilevel?
    adding_to_question_type != "select_multiple"
  end

  def first_level_option_nodes
    root_node.sorted_children
  end

  def first_level_options
    root_node.child_options
  end
  alias options first_level_options

  # checks if this option set appears in any smsable questionings
  def form_smsable?
    questionings.any?(&:form_smsable?)
  end

  def published?
    !standard? && questionings.any?(&:published?)
  end

  # Whether this OptionSet appears on any Questionings that have data.
  # Since Questionings can't change OptionSet once they have data, this is sufficient.
  def data?
    !standard? && questionings.any?(&:data?)
  end

  # Whether this OptionSet is used any Questions. We don't need to check conditions
  # because a condition can't refer to a node in this set without the set being used in a question.
  def in_use?
    question_count.positive?
  end

  # Checks if option set is used in at least one select_multiple question.
  def select_multiple_questions?
    questions.any? { |q| q.qtype_name == "select_multiple" }
  end

  def question_count
    questions.count
  end

  # gets total number of questions with which this option set is associated
  # in the case of a std option set, this includes non-standard questions that use copies of this option set
  def ttl_question_count
    question_count + copy_question_count
  end

  def copy_question_count
    standard? ? copies.to_a.sum(&:question_count) : 0
  end

  # gets all forms to which this option set is linked (through questionings)
  def forms
    questionings.collect(&:form).uniq
  end

  # gets a comma separated list of all related forms' names
  def form_names
    forms.map(&:name).join(", ")
  end

  # gets a comma separated list of all related questions' codes
  def question_codes
    questions.map(&:code).join(", ")
  end

  # Checks if any core fields (currently only name) changed
  def core_changed?
    name_changed?
  end

  # returns the localized headers to be used for export
  def headers_for_export
    [].tap do |headers|
      headers << self.class.human_attribute_name(:id)

      if multilevel?
        # use the level names as column headings for a multi-level option set
        headers.concat(levels.map(&:name))
      else
        # the human-readable name for the Option.name attribute otherwise (e.g. "Name")
        headers << Option.human_attribute_name(:name)
      end

      headers << Option.human_attribute_name(:coordinates) if allow_coordinates?
      headers << Option.human_attribute_name(:shortcode)
    end
  end

  def sms_formatting_as_inline?
    sms_formatting == "inline"
  end

  def sms_formatting_as_text?
    sms_formatting == "treat_as_text"
  end

  def sms_formatting_as_appendix?
    sms_formatting == "appendix"
  end

  def to_hash
    root_node.subtree.arrange_serializable(order: "rank")
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      {
        children: root_node.as_json(for_option_set_form: true),
        levels: levels.as_json(for_option_set_form: true)
      }
    else
      super(options)
    end
  end

  def worksheet_name
    (name.size > 31 ? name.truncate(31) : name).gsub(
      %r{[\[\]*\\?:/]},
      "[" => "(",
      "]" => ")",
      "*" => "∗",
      "?" => "",
      ":" => "-",
      "\\" => "-",
      "/" => "-"
    )
  end

  def shortcode_length
    @max_sequence ||= descendants.maximum(:sequence)&.to_i || 1
    @shortcode_length ||= Base36.digits_needed(@max_sequence)
  end

  def fetch_by_shortcode(shortcode)
    sequence = shortcode.to_i(36) - shortcode_offset
    descendants.find_by(sequence: sequence)
  end

  # Returns a string representation, including options, for the default locale.
  def to_s
    "Name: #{name}\nOptions:\n#{root_node.to_s_indented}"
  end

  if Rails.env.test?
    # Looks up an option node in this set by its name. Useful for specs.
    def node(*names)
      names.reduce(self) do |match, name|
        match = match.children.detect { |c| c.name == name }
        raise ArgumentError, "Could find option with name #{name} in set #{set}" if match.nil?
        match
      end
    end
  end

  private

  def shortcode_offset
    @shortcode_offset ||= Base36.offset(shortcode_length)
  end

  def sms_formatting
    @sms_formatting ||=
      case sms_guide_formatting
      when "auto"
        descendants.count <= 26 ? "inline" : "appendix"
      else
        sms_guide_formatting
      end
  end

  def copy_attribs_to_root_node
    root_node.assign_attributes(
      mission: mission,
      option_set: self,
      sequence: 0,
      standard_copy: standard_copy
    )
  end

  def check_associations
    return unless data?
    raise ActiveRecord::DeleteRestrictionError, "answers"
  end

  def normalize_fields
    self.name = name.strip
    self.allow_coordinates = false unless geographic?
    self.level_names = nil unless multilevel?
    true
  end

  def nullify_root_node
    update_column(:root_node_id, nil)
  end

  def save_root_node
    return unless root_node
    # Need to copy this here instead of copy_attribs_to_root_node because the ID may not exist yet
    # in the latter.
    root_node.option_set_id = id
    root_node.save!
  end
end
