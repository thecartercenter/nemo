class OptionSet < ApplicationRecord
  # We use this instead of autosave since autosave doesn't work right for belongs_to.
  # It is up here because it should happen early, e.g., before form version callbacks.
  after_save :save_root_node

  include MissionBased, FormVersionable, Replication::Standardizable, Replication::Replicable
  SMS_GUIDE_FORMATTING_OPTIONS = %w(auto inline appendix treat_as_text)

  acts_as_paranoid

  # This need to be up here or they will run too late.
  before_destroy :check_associations
  before_destroy :nullify_root_node

  has_many :questions, inverse_of: :option_set
  has_many :questionings, through: :questions
  has_many :option_nodes, -> { order(:rank) }, dependent: :destroy
  has_many :report_option_set_choices, class_name: "Report::OptionSetChoice"

  belongs_to :root_node, -> { where(option_id: nil) }, class_name: "OptionNode", dependent: :destroy

  before_validation :copy_attribs_to_root_node
  before_validation :normalize_fields

  # We do this instead of using dependent: :destroy because in the latter case
  # the dependent object doesn't know who destroyed it.
  before_destroy { report_option_set_choices.each(&:option_set_destroyed) }

  scope :by_name, -> { order("option_sets.name") }
  scope :default_order, -> { by_name }

  # replication options
  replicable(
    child_assocs: :root_node,
    backwards_assocs: :questions,
    uniqueness: {field: :name, style: :sep_words},
    dont_copy: :root_node_id
  )

  delegate :ranks_changed?,
    :children,
    :c,
    :ranks_changed?,
    :options_added?,
    :options_removed?,
    :total_options,
    :descendants,
    :all_options,
    :max_depth,
    :options_not_serialized,
    :arrange_as_rows,
    :arrange_with_options,
    :sorted_children,
    :first_leaf_option,
    :first_leaf_option_node,
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

  # Loads all options for sets with the given IDs in a constant number of queries.
  def self.all_options_for_sets(set_ids)
    return [] if set_ids.empty?
    root_node_ids = where(id: set_ids).all.map(&:root_node_id)
    where_clause = root_node_ids.map { |id| "ancestry LIKE '#{id}/%' OR ancestry = '#{id}'" }.join(" OR ")
    where_clause << " AND deleted_at IS NULL"
    Option.where("id IN (SELECT option_id FROM option_nodes WHERE #{where_clause})").to_a
  end

  def self.first_level_option_nodes_for_sets(set_ids)
    return [] if set_ids.empty?
    root_node_ids = where(id: set_ids).to_a.map(&:root_node_id)
    OptionNode.where(ancestry: root_node_ids.map(&:to_s)).includes(:option).to_a
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
    node = OptionNode.where(option_set: self, option: option).first
    return nil if node.nil?

    # Trim the root node and map to options.
    node.ancestors[1..-1].map(&:option) + [option]
  end

  # Gets the OptionLevel for the given depth (1-based)
  def level(depth)
    levels.try(:[], depth - 1)
  end

  def levels
    @levels ||= multilevel? ? level_names.map{ |n| OptionLevel.new(name_translations: n) } : nil
  end

  def levels=(ls)
    self.level_names = ls.map { |l| l.name_translations }
  end

  def level_names=(names)
    self[:level_names] = names.is_a?(Hash) ? names.values : names
  end

  def level_count
    levels.try(:size) || 1
  end

  def level_name_for_depth(depth)
    levels[depth-1].name
  end

  def multilevel?
    return @multilevel if defined?(@multilevel)
    @multilevel = !!root_node.try(:has_grandchildren?)
  end
  alias_method :multilevel, :multilevel?

  def huge?
    root_node.present? ? root_node.huge? : false
  end

  def can_be_multilevel?
    !(has_select_multiple_questions? || huge? || !question_type_supports_multilevel?)
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
  alias_method :options, :first_level_options

  # checks if this option set appears in any smsable questionings
  def form_smsable?
    questionings.any?(&:form_smsable?)
  end

  def option_has_answers?(option_id)
    # Do one query for all and cache.
    @option_ids_with_answers ||= Answer.where(
      questioning_id: questionings.map(&:id),
      option_id: descendants.map(&:option_id)
      ).pluck("DISTINCT option_id")

    # Respond to particular request.
    @option_ids_with_answers.include?(option_id)
  end

  def published?
    is_standard? ? false : questionings.any?(&:published?)
  end

  # checks if this option set is used in at least one question or if any copies are used in at least one question
  def has_questions?
    ttl_question_count > 0
  end

  # Checks if option set is used in at least one select_multiple question.
  def has_select_multiple_questions?
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
    is_standard? ? copies.to_a.sum(&:question_count) : 0
  end

  def has_answers?
    is_standard? ? copies.any?(&:has_answers?) : questionings.any?(&:has_answers?)
  end

  def has_answers_for_option?(option_id)
    questionings.any? ? Answer.any_for_option_and_questionings?(option_id, questionings.map(&:id)) : false
  end

  def answer_count
    if is_standard?
      copies.to_a.sum(&:answer_count)
    else
      questionings.to_a.sum { |q| q.answers.count }
    end
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

  def sms_formatting
    case sms_guide_formatting
    when "auto"
      (descendants.count <= 26) ? "inline" : "appendix"
    else
      sms_guide_formatting
    end
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
    name = self.name
    name = name.truncate(31) if self.name.size > 31
    name = name.gsub(
      %r{[\[\]\*\\?\:\/]}, {
        "[" => "(",
        "]" => ")",
        "*" => "∗",
        "?" => "",
        ":" => "-",
        "\\" => "-",
        "/" => "-"
      }
    )
    name
  end

  def shortcode_length
    @max_sequence ||= descendants.maximum(:sequence).try(&:to_i) || 1
    @shortcode_length ||= Base36.digits_needed(@max_sequence)
  end

  def shortcode_offset
    @shortcode_offset ||= Base36.offset(shortcode_length)
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
        match = match.children.detect { |c| c.option_name == name }
        raise ArgumentError.new("Could find option with name #{name} in set #{set}") if match.nil?
        match
      end
    end
  end

  private

  def copy_attribs_to_root_node
    root_node.assign_attributes(
      mission: mission,
      option_set: self,
      sequence: 0,
      is_standard: is_standard,
      standard_copy: standard_copy
    )
  end

  def check_associations
    # make sure not associated with any questions
    raise DeletionError.new(:cant_delete_if_has_questions) if has_questions?

    # make sure not associated with any answers
    raise DeletionError.new(:cant_delete_if_has_answers) if has_answers?
  end

  def normalize_fields
    self.name = name.strip
    self.allow_coordinates = false unless self.geographic?
    true
  end

  def nullify_root_node
    update_column(:root_node_id, nil)
  end

  def save_root_node
    if root_node
      # Need to copy this here instead of copy_attribs_to_root_node because the ID may not exist yet
      # in the latter.
      root_node.option_set_id = id
      root_node.save!
    end
  end
end
