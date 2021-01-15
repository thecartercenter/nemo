# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: form_items
#
#  id                           :uuid             not null, primary key
#  all_levels_required          :boolean          default(FALSE), not null
#  ancestry                     :text
#  ancestry_depth               :integer          not null
#  default                      :string
#  disabled                     :boolean          default(FALSE), not null
#  display_if                   :string           default("always"), not null
#  group_hint_translations      :jsonb
#  group_item_name_translations :jsonb
#  group_name_translations      :jsonb
#  hidden                       :boolean          default(FALSE), not null
#  one_screen                   :boolean
#  rank                         :integer          not null
#  read_only                    :boolean
#  repeatable                   :boolean
#  required                     :boolean          default(FALSE), not null
#  type                         :string(255)      not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  form_id                      :uuid             not null
#  form_old_id                  :integer
#  mission_id                   :uuid
#  old_id                       :integer
#  question_id                  :uuid
#  question_old_id              :integer
#
# Indexes
#
#  index_form_items_on_ancestry                 (ancestry)
#  index_form_items_on_form_id                  (form_id)
#  index_form_items_on_form_id_and_question_id  (form_id,question_id) UNIQUE
#  index_form_items_on_mission_id               (mission_id)
#  index_form_items_on_question_id              (question_id)
#
# Foreign Keys
#
#  form_items_form_id_fkey      (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  form_items_mission_id_fkey   (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  form_items_question_id_fkey  (question_id => questions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# Models the appearance of a question on a form.
class Questioning < FormItem
  include Wisper.model

  alias answers response_nodes

  delegate :all_options, :media_prompt, :media_prompt?, :auto_increment?, :code, :code=, :first_leaf_option_node,
    :first_level_option_nodes, :has_options?, :hint, :level_count, :level, :levels,
    :min_max_error_msg, :multilevel?, :multimedia?, :name, :numeric?, :odk_constraint, :odk_name,
    :option_set_id, :option_set_id=, :option_set, :option_set=, :options, :preordered_option_nodes,
    :printable?, :qtype_name, :qtype_name=, :qtype, :select_options,
    :sms_formatting_as_appendix?, :sms_formatting_as_text?, :standardized?, :subqings, :tags,
    :temporal?, :textual?, :title, :metadata_type, :reference, :select_multiple?,
    to: :question
  delegate :smsable?, to: :form, prefix: true
  delegate :group_name, to: :parent, prefix: true, allow_nil: true

  scope :with_type_property, ->(property) { joins(:question).merge(Question.with_type_property(property)) }

  validates_with Forms::DynamicPatternValidator,
    field_name: :default,
    force_calc_if: ->(qing) { qing.qtype&.numeric? }

  accepts_nested_attributes_for :question

  def published?
    form.not_draft?
  end

  # checks if this form has any answers
  # uses the form.qing_answer_count method because these requests tend to come in batches so better
  # to fetch the counts for all qings on the form at once
  def data?
    form.qing_answer_count(self).positive?
  end

  def answer_count
    answers.count
  end

  def conditions_changed?
    display_conditions.any?(&:changed?) || display_conditions.any?(&:new_record?)
  end

  def subqings
    @subqings ||=
      if multilevel?
        levels.each_with_index.map { |l, i| Subqing.new(questioning: self, level: l, rank: i + 1) }
      else
        [Subqing.new(questioning: self, rank: 1)]
      end
  end

  def core_changed?
    (changed & %w[required hidden disabled default]).any? || conditions_changed?
  end

  # Checks if this Questioning is in a repeat group.
  def repeatable?
    # Questions can only be repeatable if they're in a group, which they can't be if they're level 1.
    ancestry_depth > 1 && parent.repeatable?
  end

  def smsable?
    visible? && qtype.smsable?
  end

  # Duck type
  def fragment?
    false
  end

  def qid
    question.id
  end

  # Filter qings in a deterministic way. This allows us to pass a single qing
  # to the search filters, knowing that it will match.
  def self.filter_unique
    order(:id).uniq(&:question_id)
  end

  # REFACTOR: should use translation delegation, from abandoned std_objs branch
  def method_missing(*args)
    # pass appropriate methods on to question
    if is_question_method?(args[0].to_s)
      question.send(*args)
    else
      super
    end
  end

  def respond_to?(symbol, *)
    is_question_method?(symbol.to_s) || super
  end

  def respond_to_missing?(symbol, include_private)
    is_question_method?(symbol.to_s) || super
  end

  def is_question_method?(symbol)
    symbol.match(/\A((name|hint)_([a-z]{2})(=?))(_before_type_cast)?\z/)
  end
  # /REFACTOR

  private

  def normalize
    super
    if question.metadata_type.present?
      self.hidden = true
      display_conditions.destroy_all
    end
    # If `disabled`, don't normalize `required` in case the user wants to re-enable later.
    self.required = false if hidden? || read_only?
    self.all_levels_required = false unless multilevel? && required?
    self.default = nil if preload_last_saved?
  end
end
