class OptionSet < ActiveRecord::Base

  # We use this instead of autosave since autosave doesn't work right for belongs_to.
  # It is up here because it should happen early, e.g., before form version callbacks.
  after_save :save_root_node

  include MissionBased, FormVersionable, Replication::Standardizable, Replication::Replicable

  # This need to be up here or they will run too late.
  before_destroy :check_associations
  before_destroy :nullify_root_node

  has_many :questions, :inverse_of => :option_set
  has_many :questionings, :through => :questions
  has_many :option_nodes, dependent: :destroy
  has_many :report_option_set_choices, class_name: 'Report::OptionSetChoice'

  belongs_to :root_node, class_name: OptionNode, conditions: {option_id: nil}, dependent: :destroy

  before_validation :copy_attribs_to_root_node
  before_validation :normalize_fields

  # We do this instead of using dependent: :destroy because in the latter case
  # the dependent object doesn't know who destroyed it.
  before_destroy { report_option_set_choices.each(&:option_set_destroyed) }

  scope :by_name, order('option_sets.name')
  scope :default_order, by_name
  scope :with_assoc_counts_and_published, lambda { |mission|
    includes(:root_node).
    select(%{
      option_sets.*,
      COUNT(DISTINCT answers.id) AS answer_count_col,
      COUNT(DISTINCT questions.id) AS question_count_col,
      MAX(forms.published) AS published_col,
      COUNT(DISTINCT copy_answers.id) AS copy_answer_count_col,
      COUNT(DISTINCT copy_questions.id) AS copy_question_count_col,
      MAX(copy_forms.published) AS copy_published_col
    }).
    joins(%{
      LEFT OUTER JOIN questions ON questions.option_set_id = option_sets.id
      LEFT OUTER JOIN form_items questionings ON questionings.question_id = questions.id AND questionings.type = 'Questioning'
      LEFT OUTER JOIN forms ON forms.id = questionings.form_id
      LEFT OUTER JOIN answers ON answers.questioning_id = questionings.id
      LEFT OUTER JOIN option_sets copies ON option_sets.is_standard = 1 AND copies.original_id = option_sets.id
      LEFT OUTER JOIN questions copy_questions ON copy_questions.option_set_id = copies.id
      LEFT OUTER JOIN form_items copy_questionings ON copy_questionings.question_id = copy_questions.id AND questionings.type = 'Questioning'
      LEFT OUTER JOIN forms copy_forms ON copy_forms.id = copy_questionings.form_id
      LEFT OUTER JOIN answers copy_answers ON copy_answers.questioning_id = copy_questionings.id
    }).group('option_sets.id')}

  # replication options
  replicable child_assocs: :root_node, backwards_assocs: :questions,
    uniqueness: {field: :name, style: :sep_words},
    dont_copy: :root_node_id

  serialize :level_names, JSON

  delegate :ranks_changed?,
           :children,
           :c,
           :ranks_changed?,
           :options_added?,
           :options_removed?,
           :total_options,
           :descendants,
           :all_options,
           :options_for_node,
           :max_depth,
           :options_not_serialized,
           :arrange_with_options,
           :option_path_to_rank_path,
           :rank_path_to_option_path,
           to: :root_node

  # These methods are for the form.
  attr_writer :multi_level

  # Efficiently deletes option nodes for all option sets with given IDs.
  def self.terminate_sub_relationships(option_set_ids)
    # Must nullify these first to avoid fk error
    OptionSet.where(id: option_set_ids).update_all(root_node_id: nil)
    OptionNode.where("option_set_id IN (#{option_set_ids.join(',')})").delete_all unless option_set_ids.empty?
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
    node_where_clause = root_node_ids.map{ |id| "ancestry LIKE '#{id}/%' OR ancestry = '#{id}'" }.join(' OR ')
    Option.where("id IN (SELECT option_id FROM option_nodes WHERE #{node_where_clause})").all
  end

  def self.first_level_option_nodes_for_sets(set_ids)
    return [] if set_ids.empty?
    root_node_ids = where(id: set_ids).all.map(&:root_node_id)
    OptionNode.where(ancestry: root_node_ids.map(&:to_s)).includes(:option).all
  end

  def children_attribs=(attribs)
    build_root_node if root_node.nil?
    root_node.children_attribs = attribs
  end

  # Gets the OptionLevel for the given depth (1-based)
  def level(depth)
    levels.try(:[], depth - 1)
  end

  def levels
    @levels ||= multi_level? ? level_names.map{ |n| OptionLevel.new(name_translations: n) } : nil
  end

  def levels=(ls)
    self.level_names = ls.map{ |l| l.name_translations }
  end

  def level_count
    levels.try(:size)
  end

  def multi_level?
    @multi_level ||= root_node && root_node.has_grandchildren?
  end
  alias_method :multi_level, :multi_level?

  def huge?
    root_node.present? ? root_node.huge? : false
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
    @option_ids_with_answers ||= Answer.where(questioning_id: questionings.map(&:id),
      option_id: descendants.map(&:option_id)).pluck('DISTINCT option_id')

    # Respond to particular request.
    @option_ids_with_answers.include?(option_id)
  end

  # checks if this option set appears in any published questionings
  # uses eager loaded field if available
  def published?
    is_standard? ? false : (respond_to?(:published_col) ? published_col == 1 : questionings.any?(&:published?))
  end

  # checks if this option set is used in at least one question or if any copies are used in at least one question
  def has_questions?
    ttl_question_count > 0
  end

  # Checks if option set is used in at least one select_multiple question.
  def has_select_multiple_questions?
    questions.any?{ |q| q.qtype_name == 'select_multiple' }
  end

  # gets total number of questions with which this option set is associated
  # in the case of a std option set, this includes non-standard questions that use copies of this option set
  def ttl_question_count
    question_count + copy_question_count
  end

  # gets number of questions in which this option set is directly used
  def question_count
    respond_to?(:question_count_col) ? question_count_col || 0 : questions.count
  end

  # gets number of questions by which a copy of this option set is used
  def copy_question_count
    if is_standard?
      respond_to?(:copy_question_count_col) ? copy_question_count_col || 0 : copies.inject(0){|sum, c| sum += c.question_count}
    else
      0
    end
  end

  # checks if this option set has any answers (that is, answers to questions that use this option set)
  # or in the case of a standard option set, answers to questions that use copies of this option set
  # uses method from special eager loaded scope if available
  def has_answers?
    if is_standard?
      respond_to?(:copy_answer_count_col) ? (copy_answer_count_col || 0) > 0 : copies.any?{|c| c.questionings.any?(&:has_answers?)}
    else
      respond_to?(:answer_count_col) ? (answer_count_col || 0) > 0 : questionings.any?(&:has_answers?)
    end
  end

  def has_answers_for_option?(option_id)
    questionings.any? ? Answer.any_for_option_and_questionings?(option_id, questionings.map(&:id)) : false
  end

  # gets the number of answers to questions that use this option set
  # or in the case of a standard option set, answers to questions that use copies of this option set
  # uses method from special eager loaded scope if available
  def answer_count
    if is_standard?
      respond_to?(:copy_answer_count_col) ? copy_answer_count_col || 0 : copies.inject?(0){|sum, c| sum += c.answer_count}
    else
      respond_to?(:answer_count_col) ? answer_count_col || 0 : questionings.inject(0){|sum, q| sum += q.answers.count}
    end
  end

  # gets all forms to which this option set is linked (through questionings)
  def forms
    questionings.collect(&:form).uniq
  end

  # gets a comma separated list of all related forms' names
  def form_names
    forms.map(&:name).join(', ')
  end

  # gets a comma separated list of all related questions' codes
  def question_codes
    questions.map(&:code).join(', ')
  end

  # Checks if any core fields (currently only name) changed
  def core_changed?
    name_changed?
  end

  def to_hash
    root_node.subtree.arrange_serializable(order: 'rank')
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      {
        :children => root_node.as_json(:for_option_set_form => true),
        :levels => levels.as_json(:for_option_set_form => true)
      }
    else
      super(options)
    end
  end

  # Returns a string representation, including options, for the default locale.
  def to_s
    "Name: #{name}\nOptions:\n#{root_node.to_s_indented}"
  end

  private

    def copy_attribs_to_root_node
      root_node.assign_attributes(mission: mission, option_set: self)
    end

    def check_associations
      # make sure not associated with any questions
      raise DeletionError.new(:cant_delete_if_has_questions) if has_questions?

      # make sure not associated with any answers
      raise DeletionError.new(:cant_delete_if_has_answers) if has_answers?
    end

    def normalize_fields
      self.name = name.strip
      return true
    end

    def nullify_root_node
      update_column(:root_node_id, nil)
    end

    def save_root_node
      if root_node
        root_node.option_set = self
        root_node.save!
      end
    end
end
